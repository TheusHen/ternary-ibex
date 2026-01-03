// Copyright 2025 MHX™ Neural.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/**
 * Formal Verification Wrapper for MHX™ Ternary ALU
 *
 * This module wraps the Ternary ALU with comprehensive formal verification
 * properties using SystemVerilog Assertions (SVA) compatible with SymbiYosys.
 */

module ternary_alu_formal import ibex_pkg::*; (
  input logic clk_i,
  input logic rst_ni
);

  // Formal verification inputs
  (* anyconst *) logic [TERNARY_REG_WIDTH-1:0] operand_a;
  (* anyconst *) logic [TERNARY_REG_WIDTH-1:0] operand_b;
  (* anyconst *) ternary_op_e operator;

  // DUT outputs
  logic [TERNARY_REG_WIDTH-1:0] result;
  logic ready;
  logic overflow;
  logic [TERNARY_TRITS_PER_REG-1:0] trit_overflow;

  // Instantiate DUT
  ibex_ternary_alu dut (
    .operand_a_i    (operand_a),
    .operand_b_i    (operand_b),
    .operator_i     (operator),
    .result_o       (result),
    .ready_o        (ready),
    .overflow_o     (overflow),
    .trit_overflow_o(trit_overflow)
  );

  //////////////////////////////////////////////////////////////////////////////
  // Helper Functions
  //////////////////////////////////////////////////////////////////////////////

  // Check if a trit encoding is valid
  function automatic logic is_valid_trit(logic [1:0] trit);
    return (trit == TRIT_NEG || trit == TRIT_ZERO || trit == TRIT_POS);
  endfunction

  // Convert trit to signed integer
  function automatic logic signed [1:0] trit_to_int(logic [1:0] trit);
    case (trit)
      TRIT_NEG:  return -1;
      TRIT_ZERO: return 0;
      TRIT_POS:  return 1;
      default:   return 0;
    endcase
  endfunction

  // Convert signed integer to trit
  function automatic logic [1:0] int_to_trit(logic signed [2:0] val);
    case (val)
      -1:      return TRIT_NEG;
      0:       return TRIT_ZERO;
      1:       return TRIT_POS;
      default: return TRIT_ZERO;
    endcase
  endfunction

  //////////////////////////////////////////////////////////////////////////////
  // SECTION 1: Encoding Validity Properties
  //////////////////////////////////////////////////////////////////////////////

  // Property: All result trits must use valid encoding
  genvar i;
  generate
    for (i = 0; i < TERNARY_TRITS_PER_REG; i++) begin : g_valid_result
      ternary_alu_result_valid: assert property (
        is_valid_trit(result[i*2 +: 2])
      );
    end
  endgenerate

  //////////////////////////////////////////////////////////////////////////////
  // SECTION 2: Arithmetic Correctness Properties
  //////////////////////////////////////////////////////////////////////////////

  // For single trit testing (first trit position)
  wire [1:0] a0 = operand_a[1:0];
  wire [1:0] b0 = operand_b[1:0];
  wire [1:0] r0 = result[1:0];
  wire signed [1:0] a0_int = trit_to_int(a0);
  wire signed [1:0] b0_int = trit_to_int(b0);
  wire signed [1:0] r0_int = trit_to_int(r0);

  // Property: Addition correctness (with wrap-around)
  ternary_alu_add_correct: assert property (
    (operator == TERNARY_ADD && is_valid_trit(a0) && is_valid_trit(b0)) |->
    (r0_int == ((a0_int + b0_int + 3) % 3) - 1 ||  // Wrap-around handling
     (a0_int + b0_int >= -1 && a0_int + b0_int <= 1 && r0_int == a0_int + b0_int))
  );

  // Property: Subtraction correctness (with wrap-around)
  ternary_alu_sub_correct: assert property (
    (operator == TERNARY_SUB && is_valid_trit(a0) && is_valid_trit(b0)) |->
    (r0_int == ((a0_int - b0_int + 3) % 3) - 1 ||
     (a0_int - b0_int >= -1 && a0_int - b0_int <= 1 && r0_int == a0_int - b0_int))
  );

  // Property: Multiplication correctness
  ternary_alu_mul_correct: assert property (
    (operator == TERNARY_MUL && is_valid_trit(a0) && is_valid_trit(b0)) |->
    (r0_int == a0_int * b0_int)
  );

  // Property: AND (minimum) correctness
  ternary_alu_and_correct: assert property (
    (operator == TERNARY_AND && is_valid_trit(a0) && is_valid_trit(b0)) |->
    (r0_int == (a0_int < b0_int ? a0_int : b0_int))
  );

  // Property: OR (maximum) correctness
  ternary_alu_or_correct: assert property (
    (operator == TERNARY_OR && is_valid_trit(a0) && is_valid_trit(b0)) |->
    (r0_int == (a0_int > b0_int ? a0_int : b0_int))
  );

  // Property: NOT (negation) correctness
  ternary_alu_not_correct: assert property (
    (operator == TERNARY_NOT && is_valid_trit(a0)) |->
    (r0_int == -a0_int)
  );

  //////////////////////////////////////////////////////////////////////////////
  // SECTION 3: Algebraic Properties
  //////////////////////////////////////////////////////////////////////////////

  // Property: Addition is commutative (a + b == b + a)
  wire [TERNARY_REG_WIDTH-1:0] result_ab, result_ba;
  logic [TERNARY_REG_WIDTH-1:0] result_comm;
  logic ready_comm, overflow_comm;
  logic [TERNARY_TRITS_PER_REG-1:0] trit_overflow_comm;

  ibex_ternary_alu dut_comm (
    .operand_a_i    (operand_b),
    .operand_b_i    (operand_a),
    .operator_i     (operator),
    .result_o       (result_comm),
    .ready_o        (ready_comm),
    .overflow_o     (overflow_comm),
    .trit_overflow_o(trit_overflow_comm)
  );

  ternary_alu_add_commutative: assert property (
    (operator == TERNARY_ADD) |-> (result == result_comm)
  );

  ternary_alu_mul_commutative: assert property (
    (operator == TERNARY_MUL) |-> (result == result_comm)
  );

  ternary_alu_and_commutative: assert property (
    (operator == TERNARY_AND) |-> (result == result_comm)
  );

  ternary_alu_or_commutative: assert property (
    (operator == TERNARY_OR) |-> (result == result_comm)
  );

  //////////////////////////////////////////////////////////////////////////////
  // SECTION 4: Identity Element Properties
  //////////////////////////////////////////////////////////////////////////////

  // Property: Adding zero is identity
  ternary_alu_add_zero_identity: assert property (
    (operator == TERNARY_ADD && b0 == TRIT_ZERO && is_valid_trit(a0)) |->
    (r0 == a0)
  );

  // Property: Multiplying by +1 is identity
  ternary_alu_mul_one_identity: assert property (
    (operator == TERNARY_MUL && b0 == TRIT_POS && is_valid_trit(a0)) |->
    (r0 == a0)
  );

  // Property: Multiplying by zero yields zero
  ternary_alu_mul_zero_annihilator: assert property (
    (operator == TERNARY_MUL && (a0 == TRIT_ZERO || b0 == TRIT_ZERO)) |->
    (r0 == TRIT_ZERO)
  );

  //////////////////////////////////////////////////////////////////////////////
  // SECTION 5: Overflow Properties
  //////////////////////////////////////////////////////////////////////////////

  // Property: Multiplication never overflows
  ternary_alu_mul_no_overflow: assert property (
    (operator == TERNARY_MUL) |-> (overflow == 1'b0)
  );

  // Property: Logic operations never overflow
  ternary_alu_logic_no_overflow: assert property (
    (operator inside {TERNARY_AND, TERNARY_OR, TERNARY_XOR, TERNARY_NOT}) |->
    (overflow == 1'b0)
  );

  // Property: Addition overflow only on same-sign extremes
  ternary_alu_add_overflow_condition: assert property (
    (operator == TERNARY_ADD && trit_overflow[0]) |->
    ((a0 == TRIT_NEG && b0 == TRIT_NEG) || (a0 == TRIT_POS && b0 == TRIT_POS))
  );

  // Property: Subtraction overflow only on opposite-sign extremes
  ternary_alu_sub_overflow_condition: assert property (
    (operator == TERNARY_SUB && trit_overflow[0]) |->
    ((a0 == TRIT_NEG && b0 == TRIT_POS) || (a0 == TRIT_POS && b0 == TRIT_NEG))
  );

  //////////////////////////////////////////////////////////////////////////////
  // SECTION 6: Involution Properties
  //////////////////////////////////////////////////////////////////////////////

  // Property: NOT is self-inverse (NOT(NOT(x)) == x)
  logic [TERNARY_REG_WIDTH-1:0] not_result, not_not_result;
  logic ready_not1, ready_not2, overflow_not1, overflow_not2;
  logic [TERNARY_TRITS_PER_REG-1:0] trit_overflow_not1, trit_overflow_not2;

  ibex_ternary_alu dut_not1 (
    .operand_a_i    (operand_a),
    .operand_b_i    ('0),
    .operator_i     (TERNARY_NOT),
    .result_o       (not_result),
    .ready_o        (ready_not1),
    .overflow_o     (overflow_not1),
    .trit_overflow_o(trit_overflow_not1)
  );

  ibex_ternary_alu dut_not2 (
    .operand_a_i    (not_result),
    .operand_b_i    ('0),
    .operator_i     (TERNARY_NOT),
    .result_o       (not_not_result),
    .ready_o        (ready_not2),
    .overflow_o     (overflow_not2),
    .trit_overflow_o(trit_overflow_not2)
  );

  // Only check for valid input trits
  ternary_alu_not_involution: assert property (
    (is_valid_trit(a0)) |-> (not_not_result[1:0] == a0)
  );

  //////////////////////////////////////////////////////////////////////////////
  // SECTION 7: Timing Properties
  //////////////////////////////////////////////////////////////////////////////

  // Property: ALU is always ready (combinational)
  ternary_alu_always_ready: assert property (
    ready == 1'b1
  );

  // Property: Global overflow is OR of all trit overflows
  ternary_alu_global_overflow: assert property (
    overflow == |trit_overflow
  );

  //////////////////////////////////////////////////////////////////////////////
  // SECTION 8: Coverage Points
  //////////////////////////////////////////////////////////////////////////////

  // Cover all operations
  cover_add:    cover property (operator == TERNARY_ADD);
  cover_sub:    cover property (operator == TERNARY_SUB);
  cover_mul:    cover property (operator == TERNARY_MUL);
  cover_and:    cover property (operator == TERNARY_AND);
  cover_or:     cover property (operator == TERNARY_OR);
  cover_xor:    cover property (operator == TERNARY_XOR);
  cover_not:    cover property (operator == TERNARY_NOT);

  // Cover overflow cases
  cover_overflow:    cover property (overflow == 1'b1);
  cover_no_overflow: cover property (overflow == 1'b0);

  // Cover all trit value combinations
  cover_neg_neg: cover property (a0 == TRIT_NEG && b0 == TRIT_NEG);
  cover_neg_zero: cover property (a0 == TRIT_NEG && b0 == TRIT_ZERO);
  cover_neg_pos: cover property (a0 == TRIT_NEG && b0 == TRIT_POS);
  cover_zero_neg: cover property (a0 == TRIT_ZERO && b0 == TRIT_NEG);
  cover_zero_zero: cover property (a0 == TRIT_ZERO && b0 == TRIT_ZERO);
  cover_zero_pos: cover property (a0 == TRIT_ZERO && b0 == TRIT_POS);
  cover_pos_neg: cover property (a0 == TRIT_POS && b0 == TRIT_NEG);
  cover_pos_zero: cover property (a0 == TRIT_POS && b0 == TRIT_ZERO);
  cover_pos_pos: cover property (a0 == TRIT_POS && b0 == TRIT_POS);

endmodule
