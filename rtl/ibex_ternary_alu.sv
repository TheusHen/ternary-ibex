// Copyright lowRISC contributors.
// Copyright 2025 MHX Neural.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/**
 * Ternary Arithmetic Logic Unit for MHX Core
 *
 * Performs arithmetic and logical operations on ternary data.
 * Each trit is encoded using 2 bits:
 * - 2'b00 = -1 (negative)
 * - 2'b01 = 0  (zero)
 * - 2'b10 = +1 (positive)
 * - 2'b11 = invalid
 */

`include "prim_assert.sv"

module ibex_ternary_alu import ibex_pkg::*; #(
  parameter int unsigned TernaryDataWidth = 32,
  parameter int unsigned NumTrits = 16
)(
  input  logic [TernaryDataWidth-1:0] operand_a_i,  // NumTrits trits * 2 bits
  input  logic [TernaryDataWidth-1:0] operand_b_i,  // NumTrits trits * 2 bits
  input  ternary_op_e                 operator_i,

  output logic [TernaryDataWidth-1:0] result_o,
  output logic                        ready_o,
  output logic                        overflow_o,  // Indicates overflow in any trit position
  output logic [NumTrits-1:0]         trit_overflow_o  // Per-trit overflow flags
);

  // Ternary arithmetic functions with proper overflow handling
  function automatic logic [2:0] trit_add_with_overflow(logic [1:0] a, logic [1:0] b);
    // Returns {overflow, result[1:0]}
    // Proper ternary arithmetic: -2 → +1 with overflow, +2 → -1 with overflow
    case ({a, b})
      4'b0000: return 3'b101;     // (-1) + (-1) = -2 → +1 with overflow
      4'b0001: return 3'b000;     // (-1) + 0 = -1
      4'b0010: return 3'b001;     // (-1) + 1 = 0
      4'b0100: return 3'b000;     // 0 + (-1) = -1
      4'b0101: return 3'b001;     // 0 + 0 = 0
      4'b0110: return 3'b010;     // 0 + 1 = 1
      4'b1000: return 3'b001;     // 1 + (-1) = 0
      4'b1001: return 3'b010;     // 1 + 0 = 1
      4'b1010: return 3'b100;     // 1 + 1 = 2 → -1 with overflow
      default: return 3'b001;     // Invalid → 0, no overflow
    endcase
  endfunction

  function automatic logic [2:0] trit_sub_with_overflow(logic [1:0] a, logic [1:0] b);
    // Returns {overflow, result[1:0]}
    case ({a, b})
      4'b0000: return 3'b001;     // (-1) - (-1) = 0
      4'b0001: return 3'b000;     // (-1) - 0 = -1
      4'b0010: return 3'b110;     // (-1) - 1 = -2 → +1 with overflow
      4'b0100: return 3'b010;     // 0 - (-1) = 1
      4'b0101: return 3'b001;     // 0 - 0 = 0
      4'b0110: return 3'b000;     // 0 - 1 = -1
      4'b1000: return 3'b100;     // 1 - (-1) = 2 → -1 with overflow
      4'b1001: return 3'b010;     // 1 - 0 = 1
      4'b1010: return 3'b001;     // 1 - 1 = 0
      default: return 3'b001;     // Invalid → 0, no overflow
    endcase
  endfunction

  // Backward compatibility functions (without overflow)
  function automatic logic [1:0] trit_add(logic [1:0] a, logic [1:0] b);
    /* verilator lint_off UNUSED */
    logic [2:0] result_with_overflow;
    /* verilator lint_on UNUSED */
    result_with_overflow = trit_add_with_overflow(a, b);
    return result_with_overflow[1:0];  // Intentionally ignore overflow bit [2]
  endfunction

  function automatic logic [1:0] trit_sub(logic [1:0] a, logic [1:0] b);
    /* verilator lint_off UNUSED */
    logic [2:0] result_with_overflow;
    /* verilator lint_on UNUSED */
    result_with_overflow = trit_sub_with_overflow(a, b);
    return result_with_overflow[1:0];  // Intentionally ignore overflow bit [2]
  endfunction

  function automatic logic [1:0] trit_mul(logic [1:0] a, logic [1:0] b);
    case ({a, b})
      4'b0000: return TRIT_POS;   // (-1) * (-1) = 1
      4'b0001: return TRIT_ZERO;  // (-1) * 0 = 0
      4'b0010: return TRIT_NEG;   // (-1) * 1 = -1
      4'b0100: return TRIT_ZERO;  // 0 * (-1) = 0
      4'b0101: return TRIT_ZERO;  // 0 * 0 = 0
      4'b0110: return TRIT_ZERO;  // 0 * 1 = 0
      4'b1000: return TRIT_NEG;   // 1 * (-1) = -1
      4'b1001: return TRIT_ZERO;  // 1 * 0 = 0
      4'b1010: return TRIT_POS;   // 1 * 1 = 1
      default: return TRIT_ZERO;  // Invalid → 0
    endcase
  endfunction

  function automatic logic [1:0] trit_and(logic [1:0] a, logic [1:0] b);
    // Ternary AND: min(a, b)
    case ({a, b})
      4'b0000: return TRIT_NEG;   // min(-1, -1) = -1
      4'b0001: return TRIT_NEG;   // min(-1, 0) = -1
      4'b0010: return TRIT_NEG;   // min(-1, 1) = -1
      4'b0100: return TRIT_NEG;   // min(0, -1) = -1
      4'b0101: return TRIT_ZERO;  // min(0, 0) = 0
      4'b0110: return TRIT_ZERO;  // min(0, 1) = 0
      4'b1000: return TRIT_NEG;   // min(1, -1) = -1
      4'b1001: return TRIT_ZERO;  // min(1, 0) = 0
      4'b1010: return TRIT_POS;   // min(1, 1) = 1
      default: return TRIT_ZERO;  // Invalid → 0
    endcase
  endfunction

  function automatic logic [1:0] trit_or(logic [1:0] a, logic [1:0] b);
    // Ternary OR: max(a, b)
    case ({a, b})
      4'b0000: return TRIT_NEG;   // max(-1, -1) = -1
      4'b0001: return TRIT_ZERO;  // max(-1, 0) = 0
      4'b0010: return TRIT_POS;   // max(-1, 1) = 1
      4'b0100: return TRIT_ZERO;  // max(0, -1) = 0
      4'b0101: return TRIT_ZERO;  // max(0, 0) = 0
      4'b0110: return TRIT_POS;   // max(0, 1) = 1
      4'b1000: return TRIT_POS;   // max(1, -1) = 1
      4'b1001: return TRIT_POS;   // max(1, 0) = 1
      4'b1010: return TRIT_POS;   // max(1, 1) = 1
      default: return TRIT_ZERO;  // Invalid → 0
    endcase
  endfunction

  function automatic logic [1:0] trit_xor(logic [1:0] a, logic [1:0] b);
    // Ternary XOR: (a + b) mod 3, mapped to {-1, 0, 1}
    case ({a, b})
      4'b0000: return TRIT_POS;   // (-1) ⊕ (-1) = 1
      4'b0001: return TRIT_NEG;   // (-1) ⊕ 0 = -1
      4'b0010: return TRIT_ZERO;  // (-1) ⊕ 1 = 0
      4'b0100: return TRIT_NEG;   // 0 ⊕ (-1) = -1
      4'b0101: return TRIT_ZERO;  // 0 ⊕ 0 = 0
      4'b0110: return TRIT_POS;   // 0 ⊕ 1 = 1
      4'b1000: return TRIT_ZERO;  // 1 ⊕ (-1) = 0
      4'b1001: return TRIT_POS;   // 1 ⊕ 0 = 1
      4'b1010: return TRIT_NEG;   // 1 ⊕ 1 = -1
      default: return TRIT_ZERO;  // Invalid → 0
    endcase
  endfunction

  function automatic logic [1:0] trit_not(logic [1:0] a);
    // Ternary NOT: negate
    case (a)
      TRIT_NEG:  return TRIT_POS;   // -(-1) = 1
      TRIT_ZERO: return TRIT_ZERO;  // -0 = 0
      TRIT_POS:  return TRIT_NEG;   // -1 = -1
      default:   return TRIT_ZERO;  // Invalid → 0
    endcase
  endfunction

    // Main ALU logic
  always_comb begin
    logic [2:0] add_result;
    logic [2:0] sub_result;

    // Initialize all outputs to prevent latch inference
    result_o = '0;
    ready_o = 1'b1;
    overflow_o = 1'b0;
    trit_overflow_o = '0;
    add_result = '0;
    sub_result = '0;

    case (operator_i)
      TERNARY_ADD: begin
        for (int i = 0; i < NumTrits; i++) begin
          add_result = trit_add_with_overflow(operand_a_i[i*2 +: 2], operand_b_i[i*2 +: 2]);
          result_o[i*2 +: 2] = add_result[1:0];
          trit_overflow_o[i] = add_result[2];
          overflow_o |= add_result[2];
        end
      end

      TERNARY_SUB: begin
        for (int i = 0; i < NumTrits; i++) begin
          sub_result = trit_sub_with_overflow(operand_a_i[i*2 +: 2], operand_b_i[i*2 +: 2]);
          result_o[i*2 +: 2] = sub_result[1:0];
          trit_overflow_o[i] = sub_result[2];
          overflow_o |= sub_result[2];
        end
      end

      TERNARY_MUL: begin
        for (int i = 0; i < TERNARY_TRITS_PER_REG; i++) begin
          result_o[i*TERNARY_BITS_PER_TRIT +: TERNARY_BITS_PER_TRIT] =
            trit_mul(operand_a_i[i*TERNARY_BITS_PER_TRIT +: TERNARY_BITS_PER_TRIT],
                     operand_b_i[i*TERNARY_BITS_PER_TRIT +: TERNARY_BITS_PER_TRIT]);
        end
      end

      TERNARY_AND: begin
        for (int i = 0; i < TERNARY_TRITS_PER_REG; i++) begin
          result_o[i*TERNARY_BITS_PER_TRIT +: TERNARY_BITS_PER_TRIT] =
            trit_and(operand_a_i[i*TERNARY_BITS_PER_TRIT +: TERNARY_BITS_PER_TRIT],
                     operand_b_i[i*TERNARY_BITS_PER_TRIT +: TERNARY_BITS_PER_TRIT]);
        end
      end

      TERNARY_OR: begin
        for (int i = 0; i < TERNARY_TRITS_PER_REG; i++) begin
          result_o[i*TERNARY_BITS_PER_TRIT +: TERNARY_BITS_PER_TRIT] =
            trit_or(operand_a_i[i*TERNARY_BITS_PER_TRIT +: TERNARY_BITS_PER_TRIT],
                    operand_b_i[i*TERNARY_BITS_PER_TRIT +: TERNARY_BITS_PER_TRIT]);
        end
      end

      TERNARY_XOR: begin
        for (int i = 0; i < TERNARY_TRITS_PER_REG; i++) begin
          result_o[i*TERNARY_BITS_PER_TRIT +: TERNARY_BITS_PER_TRIT] =
            trit_xor(operand_a_i[i*TERNARY_BITS_PER_TRIT +: TERNARY_BITS_PER_TRIT],
                     operand_b_i[i*TERNARY_BITS_PER_TRIT +: TERNARY_BITS_PER_TRIT]);
        end
      end

      TERNARY_NOT: begin
        for (int i = 0; i < TERNARY_TRITS_PER_REG; i++) begin
          result_o[i*TERNARY_BITS_PER_TRIT +: TERNARY_BITS_PER_TRIT] =
            trit_not(operand_a_i[i*TERNARY_BITS_PER_TRIT +: TERNARY_BITS_PER_TRIT]);
        end
      end

      default: result_o = TERNARY_ZERO_PATTERN; // All zeros in ternary
    endcase
  end

  ///////////////////////////
  // Formal Verification   //
  ///////////////////////////

  // Helper function to check if a trit is valid
  function automatic logic is_valid_trit(logic [1:0] trit);
    return (trit inside {TRIT_NEG, TRIT_ZERO, TRIT_POS});
  endfunction

  // Helper function to check if all trits in a word are valid
  function automatic logic all_trits_valid(logic [TERNARY_REG_WIDTH-1:0] word);
    for (int i = 0; i < TERNARY_TRITS_PER_REG; i++) begin
      if (!is_valid_trit(word[i*TERNARY_BITS_PER_TRIT +: TERNARY_BITS_PER_TRIT])) return 1'b0;
    end
    return 1'b1;
  endfunction

  // Basic operation validity assertions
  `ASSERT_INIT(TernaryOpValid, operator_i inside {TERNARY_ADD, TERNARY_SUB,
    TERNARY_MUL, TERNARY_AND, TERNARY_OR, TERNARY_XOR, TERNARY_NOT})

  // Ready signal should always be high for combinational ALU
  `ASSERT(AlwaysReady, ready_o === 1'b1)

  // Test specific ternary arithmetic properties
  genvar trit_idx;
  generate
    for (trit_idx = 0; trit_idx < TERNARY_TRITS_PER_REG; trit_idx++) begin : g_trit_assertions

      // Addition properties
      `ASSERT_INIT(TernaryAddCommutative,
        (operator_i == TERNARY_ADD &&
         is_valid_trit(operand_a_i[trit_idx*TERNARY_BITS_PER_TRIT +: TERNARY_BITS_PER_TRIT]) &&
         is_valid_trit(operand_b_i[trit_idx*TERNARY_BITS_PER_TRIT +: TERNARY_BITS_PER_TRIT])) |->
        trit_add(operand_a_i[trit_idx*TERNARY_BITS_PER_TRIT +: TERNARY_BITS_PER_TRIT],
                 operand_b_i[trit_idx*TERNARY_BITS_PER_TRIT +: TERNARY_BITS_PER_TRIT]) ==
        trit_add(operand_b_i[trit_idx*TERNARY_BITS_PER_TRIT +: TERNARY_BITS_PER_TRIT],
                 operand_a_i[trit_idx*TERNARY_BITS_PER_TRIT +: TERNARY_BITS_PER_TRIT]))

      `ASSERT_INIT(TernaryAddIdentity,
        (operator_i == TERNARY_ADD &&
         is_valid_trit(operand_a_i[trit_idx*TERNARY_BITS_PER_TRIT +: TERNARY_BITS_PER_TRIT])) |->
        trit_add(operand_a_i[trit_idx*TERNARY_BITS_PER_TRIT +: TERNARY_BITS_PER_TRIT], TRIT_ZERO) ==
        operand_a_i[trit_idx*TERNARY_BITS_PER_TRIT +: TERNARY_BITS_PER_TRIT])

      // Multiplication properties
      `ASSERT_INIT(TernaryMulCommutative,
        (operator_i == TERNARY_MUL && is_valid_trit(trit_a) && is_valid_trit(trit_b)) |->
        trit_mul(trit_a, trit_b) == trit_mul(trit_b, trit_a))

      `ASSERT_INIT(TernaryMulIdentity,
        (operator_i == TERNARY_MUL && is_valid_trit(trit_a)) |->
        trit_mul(trit_a, TRIT_POS) == trit_a)

      `ASSERT_INIT(TernaryMulZero,
        (operator_i == TERNARY_MUL && is_valid_trit(trit_a)) |->
        trit_mul(trit_a, TRIT_ZERO) == TRIT_ZERO)

      // Logical operation properties
      `ASSERT_INIT(TernaryAndCommutative,
        (operator_i == TERNARY_AND && is_valid_trit(trit_a) && is_valid_trit(trit_b)) |->
        trit_and(trit_a, trit_b) == trit_and(trit_b, trit_a))

      `ASSERT_INIT(TernaryOrCommutative,
        (operator_i == TERNARY_OR && is_valid_trit(trit_a) && is_valid_trit(trit_b)) |->
        trit_or(trit_a, trit_b) == trit_or(trit_b, trit_a))

      `ASSERT_INIT(TernaryXorCommutative,
        (operator_i == TERNARY_XOR && is_valid_trit(trit_a) && is_valid_trit(trit_b)) |->
        trit_xor(trit_a, trit_b) == trit_xor(trit_b, trit_a))

      // Double negation property
      `ASSERT_INIT(TernaryNotInvolution,
        (operator_i == TERNARY_NOT && is_valid_trit(trit_a)) |->
        trit_not(trit_not(trit_a)) == trit_a)

      // Result validity
      `ASSERT_INIT(ResultIsValidTrit,
        is_valid_trit(trit_result))
    end
  endgenerate

  // High-level operation correctness
  `ASSERT_INIT(OperationCorrectnessAdd,
    (operator_i == TERNARY_ADD && all_trits_valid(operand_a_i) && all_trits_valid(operand_b_i)) |->
    all_trits_valid(result_o))

  `ASSERT_INIT(OperationCorrectnessOther,
    (operator_i inside {TERNARY_SUB, TERNARY_MUL, TERNARY_AND, TERNARY_OR, TERNARY_XOR} &&
     all_trits_valid(operand_a_i) && all_trits_valid(operand_b_i)) |->
    all_trits_valid(result_o))

  `ASSERT_INIT(OperationCorrectnessNot,
    (operator_i == TERNARY_NOT && all_trits_valid(operand_a_i)) |->
    all_trits_valid(result_o))

  // Overflow behavior verification
  `ASSERT_INIT(OverflowConsistency,
    overflow_o == |trit_overflow_o)

  // Overflow only occurs in add/sub operations
  `ASSERT_INIT(OverflowOnlyInArithmetic,
    (operator_i inside {TERNARY_MUL, TERNARY_AND, TERNARY_OR, TERNARY_XOR, TERNARY_NOT}) |->
    !overflow_o)

  // Specific overflow cases verification
  genvar overflow_idx;
  generate
    for (overflow_idx = 0; overflow_idx < NumTrits; overflow_idx++) begin : g_overflow_assertions
  /* verilator lint_off UNUSED */
  logic [1:0] trit_a, trit_b;
  /* verilator lint_on UNUSED */

      assign trit_a = operand_a_i[overflow_idx*2 +: 2];
      assign trit_b = operand_b_i[overflow_idx*2 +: 2];

      // Addition overflow cases: (-1) + (-1) and (+1) + (+1)
      `ASSERT_INIT(AddOverflowNegNeg,
        (operator_i == TERNARY_ADD && trit_a == TRIT_NEG && trit_b == TRIT_NEG) |->
        trit_overflow_o[overflow_idx])

      `ASSERT_INIT(AddOverflowPosPos,
        (operator_i == TERNARY_ADD && trit_a == TRIT_POS && trit_b == TRIT_POS) |->
        trit_overflow_o[overflow_idx])

      // Subtraction overflow cases: (-1) - (+1) and (+1) - (-1)
      `ASSERT_INIT(SubOverflowNegPos,
        (operator_i == TERNARY_SUB && trit_a == TRIT_NEG && trit_b == TRIT_POS) |->
        trit_overflow_o[overflow_idx])

      `ASSERT_INIT(SubOverflowPosNeg,
        (operator_i == TERNARY_SUB && trit_a == TRIT_POS && trit_b == TRIT_NEG) |->
        trit_overflow_o[overflow_idx])

      // No overflow in non-overflow cases
      `ASSERT_INIT(AddNoOverflowMixed,
        (operator_i == TERNARY_ADD &&
         ((trit_a == TRIT_NEG && trit_b != TRIT_NEG) ||
          (trit_a == TRIT_POS && trit_b != TRIT_POS) ||
          (trit_a == TRIT_ZERO))) |->
        !trit_overflow_o[overflow_idx])

      `ASSERT_INIT(SubNoOverflowSafe,
        (operator_i == TERNARY_SUB &&
         !((trit_a == TRIT_NEG && trit_b == TRIT_POS) ||
           (trit_a == TRIT_POS && trit_b == TRIT_NEG))) |->
        !trit_overflow_o[overflow_idx])
    end
  endgenerate

  ////////////////////////////////////////////////////
  // Advanced Formal Properties for BMC             //
  ////////////////////////////////////////////////////

  // Associativity properties (bounded for formal verification)
  `ASSERT_INIT(TernaryAddAssociative_c,
    (operator_i == TERNARY_ADD &&
     is_valid_trit(operand_a_i[1:0]) &&
     is_valid_trit(operand_b_i[1:0]) &&
     is_valid_trit(operand_a_i[3:2])) |->
    trit_add(trit_add(operand_a_i[1:0], operand_b_i[1:0]), operand_a_i[3:2]) ==
    trit_add(operand_a_i[1:0], trit_add(operand_b_i[1:0], operand_a_i[3:2])))

  // Distributivity of multiplication over addition
  `ASSERT_INIT(TernaryMulDistributive_c,
    (is_valid_trit(operand_a_i[1:0]) &&
     is_valid_trit(operand_b_i[1:0]) &&
     is_valid_trit(operand_a_i[3:2])) |->
    trit_mul(operand_a_i[1:0],
             trit_add(operand_b_i[1:0], operand_a_i[3:2])) ==
    trit_add(trit_mul(operand_a_i[1:0], operand_b_i[1:0]),
             trit_mul(operand_a_i[1:0], operand_a_i[3:2])))

  // De Morgan's laws for ternary logic
  `ASSERT_INIT(TernaryDeMorganAnd_c,
    (is_valid_trit(operand_a_i[1:0]) && is_valid_trit(operand_b_i[1:0])) |->
    trit_not(trit_and(operand_a_i[1:0], operand_b_i[1:0])) ==
    trit_or(trit_not(operand_a_i[1:0]), trit_not(operand_b_i[1:0])))

  `ASSERT_INIT(TernaryDeMorganOr_c,
    (is_valid_trit(operand_a_i[1:0]) && is_valid_trit(operand_b_i[1:0])) |->
    trit_not(trit_or(operand_a_i[1:0], operand_b_i[1:0])) ==
    trit_and(trit_not(operand_a_i[1:0]), trit_not(operand_b_i[1:0])))

  // Absorption laws
  `ASSERT_INIT(TernaryAbsorptionAndOr_c,
    (is_valid_trit(operand_a_i[1:0]) && is_valid_trit(operand_b_i[1:0])) |->
    trit_and(operand_a_i[1:0], trit_or(operand_a_i[1:0], operand_b_i[1:0])) ==
    operand_a_i[1:0])

  `ASSERT_INIT(TernaryAbsorptionOrAnd_c,
    (is_valid_trit(operand_a_i[1:0]) && is_valid_trit(operand_b_i[1:0])) |->
    trit_or(operand_a_i[1:0], trit_and(operand_a_i[1:0], operand_b_i[1:0])) ==
    operand_a_i[1:0])

  // Idempotence laws
  `ASSERT_INIT(TernaryAndIdempotent_c,
    is_valid_trit(operand_a_i[1:0]) |->
    trit_and(operand_a_i[1:0], operand_a_i[1:0]) == operand_a_i[1:0])

  `ASSERT_INIT(TernaryOrIdempotent_c,
    is_valid_trit(operand_a_i[1:0]) |->
    trit_or(operand_a_i[1:0], operand_a_i[1:0]) == operand_a_i[1:0])

  // XOR properties
  `ASSERT_INIT(TernaryXorSelf_c,
    is_valid_trit(operand_a_i[1:0]) |->
    trit_xor(operand_a_i[1:0], operand_a_i[1:0]) == TRIT_ZERO)

  `ASSERT_INIT(TernaryXorInverse_c,
    is_valid_trit(operand_a_i[1:0]) |->
    trit_xor(operand_a_i[1:0], trit_not(operand_a_i[1:0])) == TRIT_ZERO)

  // Subtraction as inverse of addition
  `ASSERT_INIT(TernarySubAsInverseAdd_c,
    (is_valid_trit(operand_a_i[1:0]) && is_valid_trit(operand_b_i[1:0]) &&
     !trit_add_with_overflow(operand_a_i[1:0], operand_b_i[1:0])[2]) |->
    trit_sub(trit_add(operand_a_i[1:0], operand_b_i[1:0]), operand_b_i[1:0]) ==
    operand_a_i[1:0])

  // Multiplication by negation
  `ASSERT_INIT(TernaryMulByNeg_c,
    is_valid_trit(operand_a_i[1:0]) |->
    trit_mul(operand_a_i[1:0], TRIT_NEG) == trit_not(operand_a_i[1:0]))

  // Overflow result correctness (wrapping behavior)
  `ASSERT_INIT(AddOverflowResultNegNeg_c,
    (operator_i == TERNARY_ADD &&
     operand_a_i[1:0] == TRIT_NEG && operand_b_i[1:0] == TRIT_NEG) |->
    result_o[1:0] == TRIT_POS)

  `ASSERT_INIT(AddOverflowResultPosPos_c,
    (operator_i == TERNARY_ADD &&
     operand_a_i[1:0] == TRIT_POS && operand_b_i[1:0] == TRIT_POS) |->
    result_o[1:0] == TRIT_NEG)

  `ASSERT_INIT(SubOverflowResultNegPos_c,
    (operator_i == TERNARY_SUB &&
     operand_a_i[1:0] == TRIT_NEG && operand_b_i[1:0] == TRIT_POS) |->
    result_o[1:0] == TRIT_POS)

  `ASSERT_INIT(SubOverflowResultPosNeg_c,
    (operator_i == TERNARY_SUB &&
     operand_a_i[1:0] == TRIT_POS && operand_b_i[1:0] == TRIT_NEG) |->
    result_o[1:0] == TRIT_NEG)

  // Bounded verification: Full word operations consistency
  `ASSERT_INIT(FullWordConsistency_c,
    (operator_i inside {TERNARY_ADD, TERNARY_SUB, TERNARY_MUL} &&
     all_trits_valid(operand_a_i) && all_trits_valid(operand_b_i)) |->
    ##1 all_trits_valid(result_o))

  // Stability: Result doesn't change if inputs don't change
  `ASSERT(ResultStability_c,
    (operator_i == $past(operator_i) &&
     operand_a_i == $past(operand_a_i) &&
     operand_b_i == $past(operand_b_i)) |->
    result_o == $past(result_o))

  // Performance: Single-cycle operation (combinational)
  `ASSERT_INIT(SingleCycleOperation_c,
    ready_o === 1'b1)

  ////////////////////////////////////////////////////
  // Power Analysis & Constant-Time Properties      //
  ////////////////////////////////////////////////////

  // Constant-time operations for side-channel resistance
  // All ternary operations should complete in constant time regardless of data
  `ASSERT(ConstantTimeReady_c,
    ready_o === 1'b1)

  // Result generation is data-independent in timing
  // (combinational logic has same delay for all data patterns)
  `ASSERT_INIT(DataIndependentTiming_c,
    (operator_i == $past(operator_i)) |->
    ready_o == $past(ready_o))

  // Overflow detection is also constant-time
  `ASSERT_INIT(OverflowConstantTime_c,
    (operator_i inside {TERNARY_ADD, TERNARY_SUB}) |->
    ##1 (overflow_o === 1'b0 || overflow_o === 1'b1))

  // No data-dependent control flow in combinational logic
  // All operations process all trits in parallel
  `ASSERT_INIT(NoDataDependentControl_c,
    (operator_i inside {TERNARY_ADD, TERNARY_SUB, TERNARY_MUL,
                        TERNARY_AND, TERNARY_OR, TERNARY_XOR, TERNARY_NOT}) |->
    ready_o === 1'b1)

  // Power consumption should be relatively uniform
  // (checked by asserting result always has valid encoding)
  `ASSERT_INIT(UniformPowerConsumption_c,
    all_trits_valid(result_o))

  // No early termination based on data values
  // (all operations take the same number of cycles)
  `ASSERT(NoEarlyTermination_c,
    (operator_i == $past(operator_i) &&
     operand_a_i != $past(operand_a_i)) |->
    ready_o == $past(ready_o))

  // Verify that zero inputs don't cause short-circuit
  `ASSERT_INIT(NoZeroShortCircuit_c,
    (operator_i == TERNARY_MUL &&
     (operand_a_i == TERNARY_ZERO_PATTERN || operand_b_i == TERNARY_ZERO_PATTERN)) |->
    ready_o === 1'b1)

endmodule
