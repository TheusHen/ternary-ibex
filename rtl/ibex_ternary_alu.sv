// Copyright lowRISC contributors.
// Copyright 2025 MHX Neural.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/**
 * MHX Ternary Arithmetic Logic Unit (ALU)
 *
 * Native ternary (base-3) arithmetic and logic operations:
 * - 7 Core Operations: ADD, SUB, MUL, AND, OR, XOR, NOT
 * - Per-trit and global overflow detection
 * - Element-wise parallel processing (16 trits)
 * - Zero-wait combinational logic
 *
 * Trit Encoding (2 bits per trit):
 * - 2'b00 = -1 (TRIT_NEG)
 * - 2'b01 =  0 (TRIT_ZERO)
 * - 2'b10 = +1 (TRIT_POS)
 * - 2'b11 = Invalid (treated as 0)
 */

`include "prim_assert.sv"

module ibex_ternary_alu import ibex_pkg::*; (
  input  logic [TERNARY_REG_WIDTH-1:0] operand_a_i,
  input  logic [TERNARY_REG_WIDTH-1:0] operand_b_i,
  input  ternary_op_e                  operator_i,

  output logic [TERNARY_REG_WIDTH-1:0] result_o,
  output logic                         ready_o,
  output logic                         overflow_o,
  output logic [TERNARY_TRITS_PER_REG-1:0] trit_overflow_o
);

  // Internal signals for each trit position
  logic [1:0] result_trits [TERNARY_TRITS_PER_REG];
  logic       overflow_trits [TERNARY_TRITS_PER_REG];

  // Convert trit encoding to signed integer
  function automatic logic signed [1:0] trit_to_int(logic [1:0] trit);
    case (trit)
      TRIT_NEG:  return -1;
      TRIT_ZERO: return 0;
      TRIT_POS:  return 1;
      default:   return 0;  // Invalid encoding treated as zero
    endcase
  endfunction

  // Convert signed integer back to trit encoding
  function automatic logic [1:0] int_to_trit(logic signed [2:0] val);
    case (val)
      -1:      return TRIT_NEG;
      0:       return TRIT_ZERO;
      1:       return TRIT_POS;
      default: return TRIT_ZERO;  // Overflow case, handled separately
    endcase
  endfunction

  // Ternary addition with overflow detection
  function automatic logic [2:0] trit_add(logic [1:0] a, logic [1:0] b);
    logic signed [2:0] result;
    logic overflow;

    result = trit_to_int(a) + trit_to_int(b);
    overflow = (result > 1) || (result < -1);

    // Wrap around for ternary arithmetic
    if (result > 1) result = result - 3;
    else if (result < -1) result = result + 3;

    return {overflow, int_to_trit(result)};
  endfunction

  // Ternary subtraction with overflow detection
  function automatic logic [2:0] trit_sub(logic [1:0] a, logic [1:0] b);
    logic signed [2:0] result;
    logic overflow;

    result = trit_to_int(a) - trit_to_int(b);
    overflow = (result > 1) || (result < -1);

    // Wrap around for ternary arithmetic
    if (result > 1) result = result - 3;
    else if (result < -1) result = result + 3;

    return {overflow, int_to_trit(result)};
  endfunction

  // Ternary multiplication (never overflows)
  function automatic logic [1:0] trit_mul(logic [1:0] a, logic [1:0] b);
    logic signed [2:0] result;

    result = trit_to_int(a) * trit_to_int(b);
    return int_to_trit(result);  // Result always in [-1, 1]
  endfunction

  // Ternary AND (minimum)
  function automatic logic [1:0] trit_and(logic [1:0] a, logic [1:0] b);
    logic signed [1:0] a_int, b_int;
    a_int = trit_to_int(a);
    b_int = trit_to_int(b);

    if (a_int < b_int) return a;
    else return b;
  endfunction

  // Ternary OR (maximum)
  function automatic logic [1:0] trit_or(logic [1:0] a, logic [1:0] b);
    logic signed [1:0] a_int, b_int;
    a_int = trit_to_int(a);
    b_int = trit_to_int(b);

    if (a_int > b_int) return a;
    else return b;
  endfunction

  // Ternary XOR (addition mod 3)
  function automatic logic [1:0] trit_xor(logic [1:0] a, logic [1:0] b);
    logic signed [2:0] result;

    result = trit_to_int(a) + trit_to_int(b);

    // Modulo 3 arithmetic
    if (result > 1) result = result - 3;
    else if (result < -1) result = result + 3;

    return int_to_trit(result);
  endfunction

  // Ternary NOT (negation)
  function automatic logic [1:0] trit_not(logic [1:0] a);
    case (a)
      TRIT_NEG:  return TRIT_POS;
      TRIT_ZERO: return TRIT_ZERO;
      TRIT_POS:  return TRIT_NEG;
      default:   return TRIT_ZERO;
    endcase
  endfunction

  // Main ALU logic - process all trits in parallel
  always_comb begin
    // Initialize outputs
    for (int i = 0; i < TERNARY_TRITS_PER_REG; i++) begin
      result_trits[i] = TRIT_ZERO;
      overflow_trits[i] = 1'b0;
    end

    // Process each trit position
    for (int i = 0; i < TERNARY_TRITS_PER_REG; i++) begin
      logic [1:0] a_trit, b_trit;
      logic [2:0] add_sub_result;

      a_trit = operand_a_i[i*TERNARY_BITS_PER_TRIT +: TERNARY_BITS_PER_TRIT];
      b_trit = operand_b_i[i*TERNARY_BITS_PER_TRIT +: TERNARY_BITS_PER_TRIT];
      add_sub_result = 3'b000;  // Initialize to prevent latch

      case (operator_i)
        TERNARY_ADD: begin
          add_sub_result = trit_add(a_trit, b_trit);
          result_trits[i] = add_sub_result[1:0];
          overflow_trits[i] = add_sub_result[2];
        end

        TERNARY_SUB: begin
          add_sub_result = trit_sub(a_trit, b_trit);
          result_trits[i] = add_sub_result[1:0];
          overflow_trits[i] = add_sub_result[2];
        end

        TERNARY_MUL: begin
          result_trits[i] = trit_mul(a_trit, b_trit);
          overflow_trits[i] = 1'b0;  // Multiplication never overflows
        end

        TERNARY_AND: begin
          result_trits[i] = trit_and(a_trit, b_trit);
          overflow_trits[i] = 1'b0;
        end

        TERNARY_OR: begin
          result_trits[i] = trit_or(a_trit, b_trit);
          overflow_trits[i] = 1'b0;
        end

        TERNARY_XOR: begin
          result_trits[i] = trit_xor(a_trit, b_trit);
          overflow_trits[i] = 1'b0;
        end

        TERNARY_NOT: begin
          result_trits[i] = trit_not(a_trit);
          overflow_trits[i] = 1'b0;
        end

        default: begin
          result_trits[i] = TRIT_ZERO;
          overflow_trits[i] = 1'b0;
        end
      endcase
    end
  end

  // Combine individual trit results into output
  always_comb begin
    result_o = '0;
    for (int i = 0; i < TERNARY_TRITS_PER_REG; i++) begin
      result_o[i*TERNARY_BITS_PER_TRIT +: TERNARY_BITS_PER_TRIT] = result_trits[i];
      trit_overflow_o[i] = overflow_trits[i];
    end
  end

  // Global overflow is OR of all trit overflows
  assign overflow_o = |trit_overflow_o;

  // ALU is always ready (combinational)
  assign ready_o = 1'b1;

  ///////////////////////////
  // Formal Verification   //
  ///////////////////////////

  // Result is valid ternary encoding (no 2'b11)
  `ASSERT(ResultValidTernary,
    result_o[1:0] inside {TRIT_NEG, TRIT_ZERO, TRIT_POS})

  // Multiplication never overflows
  `ASSERT(MulNoOverflow,
    (operator_i == TERNARY_MUL) |-> (overflow_o == 1'b0))

  // NOT is self-inverse: NOT(NOT(x)) == x
  // (Property for formal verification tools)

  // AND is commutative: AND(a,b) == AND(b,a)
  // (Property for formal verification tools)

  // OR is commutative: OR(a,b) == OR(b,a)
  // (Property for formal verification tools)

  // Addition overflow only on (-1)+(-1) or (+1)+(+1)
  `ASSERT(AddOverflowCondition,
    (operator_i == TERNARY_ADD && overflow_trits[0]) |->
    ((operand_a_i[1:0] == TRIT_NEG && operand_b_i[1:0] == TRIT_NEG) ||
     (operand_a_i[1:0] == TRIT_POS && operand_b_i[1:0] == TRIT_POS)))

  // Subtraction overflow only on (-1)-(+1) or (+1)-(-1)
  `ASSERT(SubOverflowCondition,
    (operator_i == TERNARY_SUB && overflow_trits[0]) |->
    ((operand_a_i[1:0] == TRIT_NEG && operand_b_i[1:0] == TRIT_POS) ||
     (operand_a_i[1:0] == TRIT_POS && operand_b_i[1:0] == TRIT_NEG)))

  // Zero operand properties
  `ASSERT(AddZeroIdentity,
    (operator_i == TERNARY_ADD && operand_b_i[1:0] == TRIT_ZERO) |->
    (result_o[1:0] == operand_a_i[1:0]))

  `ASSERT(MulZeroResult,
    (operator_i == TERNARY_MUL &&
     (operand_a_i[1:0] == TRIT_ZERO || operand_b_i[1:0] == TRIT_ZERO)) |->
    (result_o[1:0] == TRIT_ZERO))

endmodule
