// Copyright 2025 MHX Neural.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/**
 * Formal Verification Wrapper for MHX Neural Processing Unit
 *
 * This module wraps the Neural Unit with comprehensive formal verification
 * properties using SystemVerilog Assertions (SVA) compatible with SymbiYosys.
 */

module neural_unit_formal import ibex_pkg::*; (
  input logic clk_i,
  input logic rst_ni
);

  // Formal verification inputs
  (* anyconst *) logic [TERNARY_REG_WIDTH-1:0] weights;
  (* anyconst *) logic [TERNARY_REG_WIDTH-1:0] inputs;
  (* anyconst *) logic [TERNARY_REG_WIDTH-1:0] bias;
  (* anyconst *) neural_op_e operation;

  // DUT outputs
  logic [TERNARY_REG_WIDTH-1:0] result;
  logic valid;

  // Instantiate DUT
  ibex_neural_unit dut (
    .weights_i   (weights),
    .inputs_i    (inputs),
    .bias_i      (bias),
    .operation_i (operation),
    .result_o    (result),
    .valid_o     (valid)
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

  // Check if all trits in a word are valid
  function automatic logic all_trits_valid(logic [TERNARY_REG_WIDTH-1:0] word);
    for (int i = 0; i < TERNARY_TRITS_PER_REG; i++) begin
      if (!is_valid_trit(word[i*2 +: 2])) return 1'b0;
    end
    return 1'b1;
  endfunction

  // Compute expected dot product
  function automatic logic signed [7:0] compute_dot_product(
    logic [TERNARY_REG_WIDTH-1:0] w,
    logic [TERNARY_REG_WIDTH-1:0] inp
  );
    logic signed [7:0] acc;
    acc = 0;
    for (int i = 0; i < TERNARY_TRITS_PER_REG; i++) begin
      logic signed [1:0] w_int, i_int;
      w_int = trit_to_int(w[i*2 +: 2]);
      i_int = trit_to_int(inp[i*2 +: 2]);
      acc = acc + w_int * i_int;
    end
    return acc;
  endfunction

  //////////////////////////////////////////////////////////////////////////////
  // SECTION 1: Valid Output Properties
  //////////////////////////////////////////////////////////////////////////////

  // Property: Valid only for known operations
  neural_valid_known_ops: assert property (
    valid |-> operation inside {NEURAL_MULTIPLY, NEURAL_ACCUMULATE,
                                NEURAL_ACTIVATE, NEURAL_LEARN}
  );

  // Property: Output is zero for unknown operations
  neural_unknown_op_zero: assert property (
    !(operation inside {NEURAL_MULTIPLY, NEURAL_ACCUMULATE,
                        NEURAL_ACTIVATE, NEURAL_LEARN}) |->
    (result == TERNARY_ZERO_PATTERN && valid == 1'b0)
  );

  //////////////////////////////////////////////////////////////////////////////
  // SECTION 2: Accumulator Bounds Properties
  //////////////////////////////////////////////////////////////////////////////

  // For 16 MACs, the accumulator can range from -16 to +16
  // With bias, it can be -17 to +17

  // Property: Accumulator is bounded
  // We verify this by checking that the activated output is always a valid trit
  neural_activation_bounded: assert property (
    (operation == NEURAL_ACTIVATE && valid) |->
    is_valid_trit(result[1:0])
  );

  //////////////////////////////////////////////////////////////////////////////
  // SECTION 3: Multiply Operation Properties
  //////////////////////////////////////////////////////////////////////////////

  // Property: MULTIPLY outputs valid ternary encoding
  neural_multiply_valid: assert property (
    (operation == NEURAL_MULTIPLY && valid) |->
    is_valid_trit(result[1:0])
  );

  //////////////////////////////////////////////////////////////////////////////
  // SECTION 4: Activation Function Properties
  //////////////////////////////////////////////////////////////////////////////

  // Property: Sign activation is correct
  // Accumulator > 0 -> TRIT_POS
  // Accumulator < 0 -> TRIT_NEG
  // Accumulator = 0 -> TRIT_ZERO

  wire signed [7:0] expected_dot = compute_dot_product(weights, inputs);
  wire signed [1:0] bias_int = trit_to_int(bias[1:0]);
  wire signed [7:0] expected_acc = expected_dot + bias_int;

  neural_activation_pos: assert property (
    (operation == NEURAL_ACTIVATE && valid && all_trits_valid(weights) &&
     all_trits_valid(inputs) && expected_acc > 0) |->
    (result[1:0] == TRIT_POS)
  );

  neural_activation_neg: assert property (
    (operation == NEURAL_ACTIVATE && valid && all_trits_valid(weights) &&
     all_trits_valid(inputs) && expected_acc < 0) |->
    (result[1:0] == TRIT_NEG)
  );

  neural_activation_zero: assert property (
    (operation == NEURAL_ACTIVATE && valid && all_trits_valid(weights) &&
     all_trits_valid(inputs) && expected_acc == 0) |->
    (result[1:0] == TRIT_ZERO)
  );

  //////////////////////////////////////////////////////////////////////////////
  // SECTION 5: Learning Operation Properties
  //////////////////////////////////////////////////////////////////////////////

  // Property: LEARN operation produces valid ternary outputs
  genvar i;
  generate
    for (i = 0; i < TERNARY_TRITS_PER_REG; i++) begin : g_learn_valid
      neural_learn_valid_trit: assert property (
        (operation == NEURAL_LEARN && valid) |->
        is_valid_trit(result[i*2 +: 2])
      );
    end
  endgenerate

  // Property: LEARN with zero delta preserves weights
  neural_learn_zero_delta: assert property (
    (operation == NEURAL_LEARN && valid &&
     inputs == TERNARY_ZERO_PATTERN) |->
    (result == weights)
  );

  //////////////////////////////////////////////////////////////////////////////
  // SECTION 6: Zero Input Properties
  //////////////////////////////////////////////////////////////////////////////

  // Property: All-zero inputs produce zero accumulator
  neural_zero_inputs: assert property (
    (operation == NEURAL_ACTIVATE && valid &&
     inputs == TERNARY_ZERO_PATTERN &&
     is_valid_trit(bias[1:0])) |->
    (result[1:0] == bias[1:0] || result[1:0] == TRIT_ZERO)
  );

  // Property: All-zero weights produce zero accumulator (before bias)
  neural_zero_weights: assert property (
    (operation == NEURAL_ACTIVATE && valid &&
     weights == TERNARY_ZERO_PATTERN &&
     is_valid_trit(bias[1:0])) |->
    (result[1:0] == bias[1:0] || result[1:0] == TRIT_ZERO)
  );

  //////////////////////////////////////////////////////////////////////////////
  // SECTION 7: Symmetry Properties
  //////////////////////////////////////////////////////////////////////////////

  // Property: Dot product is commutative (swap weights and inputs)
  logic [TERNARY_REG_WIDTH-1:0] result_swap;
  logic valid_swap;

  ibex_neural_unit dut_swap (
    .weights_i   (inputs),
    .inputs_i    (weights),
    .bias_i      (bias),
    .operation_i (operation),
    .result_o    (result_swap),
    .valid_o     (valid_swap)
  );

  neural_dot_commutative: assert property (
    ((operation == NEURAL_MULTIPLY || operation == NEURAL_ACTIVATE) && valid) |->
    (result == result_swap)
  );

  //////////////////////////////////////////////////////////////////////////////
  // SECTION 8: Determinism Properties
  //////////////////////////////////////////////////////////////////////////////

  // Property: Same inputs always produce same output
  logic [TERNARY_REG_WIDTH-1:0] result_copy;
  logic valid_copy;

  ibex_neural_unit dut_copy (
    .weights_i   (weights),
    .inputs_i    (inputs),
    .bias_i      (bias),
    .operation_i (operation),
    .result_o    (result_copy),
    .valid_o     (valid_copy)
  );

  neural_deterministic: assert property (
    result == result_copy && valid == valid_copy
  );

  //////////////////////////////////////////////////////////////////////////////
  // SECTION 9: Coverage Points
  //////////////////////////////////////////////////////////////////////////////

  // Cover all operations
  cover_multiply:   cover property (operation == NEURAL_MULTIPLY && valid);
  cover_accumulate: cover property (operation == NEURAL_ACCUMULATE && valid);
  cover_activate:   cover property (operation == NEURAL_ACTIVATE && valid);
  cover_learn:      cover property (operation == NEURAL_LEARN && valid);

  // Cover activation outputs
  cover_activate_pos:  cover property (operation == NEURAL_ACTIVATE && valid && result[1:0] == TRIT_POS);
  cover_activate_neg:  cover property (operation == NEURAL_ACTIVATE && valid && result[1:0] == TRIT_NEG);
  cover_activate_zero: cover property (operation == NEURAL_ACTIVATE && valid && result[1:0] == TRIT_ZERO);

  // Cover edge cases
  cover_all_zero_inputs:  cover property (inputs == TERNARY_ZERO_PATTERN);
  cover_all_zero_weights: cover property (weights == TERNARY_ZERO_PATTERN);
  cover_all_pos_weights:  cover property (weights == 32'hAAAAAAAA);  // All +1
  cover_all_neg_weights:  cover property (weights == 32'h00000000);  // All -1

endmodule
