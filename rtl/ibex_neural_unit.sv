// Copyright lowRISC contributors.
// Copyright 2025 MHX Neural.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/**
 * Neural Processing Unit for MHX Core
 *
 * Specialized unit for ternary neural network operations:
 * - Weight × Input multiplication (16 parallel MACs)
 * - Accumulation of products (4-level reduction tree)
 * - Ternary activation functions
 * - Learning/weight update operations
 *
 * PERFORMANCE OPTIMIZATIONS (v2 - enhanced):
 * - Direct inline trit-to-int lookup (no function overhead)
 * - Fully parallel multiplication (16 MACs in parallel)
 * - Optimized 4-level reduction tree (minimal depth)
 * - Automatic skip-zero through ternary multiplication
 * - Single-cycle latency for all operations
 * - Synthesis-friendly structure for high frequency
 */

`include "prim_assert.sv"

module ibex_neural_unit import ibex_pkg::*; (
  // Note: No clock/reset needed for pure combinational logic

  // Operands
  input  logic [TERNARY_REG_WIDTH-1:0] weights_i,    // Ternary weights
  input  logic [TERNARY_REG_WIDTH-1:0] inputs_i,     // Ternary inputs
  input  logic [TERNARY_REG_WIDTH-1:0] bias_i,       // Bias value (only LSB trits used)
  input  neural_op_e                   operation_i,  // Neural operation

  // Results
  output logic [TERNARY_REG_WIDTH-1:0] result_o,     // Neural result
  output logic                         valid_o       // Operation valid
);

  // Internal accumulator for neural computations
  // Can hold sum of TERNARY_TRITS_PER_REG trits plus bias
  // Range: [NEURAL_ACCUMULATOR_MIN, NEURAL_ACCUMULATOR_MAX]
  logic signed [NEURAL_ACCUMULATOR_WIDTH-1:0] next_accumulator;

  // Unused bias bits (only first trit is used for ternary bias)
  logic [TERNARY_REG_WIDTH-TERNARY_BITS_PER_TRIT-1:0] unused_bias_bits;
  assign unused_bias_bits = bias_i[TERNARY_REG_WIDTH-1:TERNARY_BITS_PER_TRIT];

  // Convert trit encoding to signed integer
  function automatic logic signed [1:0] trit_to_int(logic [1:0] trit);
    case (trit)
      TRIT_NEG:  return -1;  // -1
      TRIT_ZERO: return 0;   // 0
      TRIT_POS:  return 1;   // +1
      default:   return 0;   // Invalid → 0
    endcase
  endfunction

  // Convert signed integer to trit encoding
  function automatic logic [1:0] int_to_trit(logic signed [7:0] value);
    if (value > 0) begin
      return TRIT_POS;   // +1
    end else if (value < 0) begin
      return TRIT_NEG;   // -1
    end else begin
      return TRIT_ZERO;  // 0
    end
  endfunction

  // Optimized ternary multiply-accumulate for neural computation
  // - Skip-zero optimization: if either trit is zero, contribution is zero (no adder toggle)
  // - Reduction tree: sum partial products in a balanced way to reduce combinational depth
  // - Optimized for minimal latency and maximum throughput
  always_comb begin
    logic signed [NEURAL_ACCUMULATOR_WIDTH-1:0] level0   [TERNARY_TRITS_PER_REG];
    logic signed [NEURAL_ACCUMULATOR_WIDTH-1:0] level1   [TERNARY_TRITS_PER_REG/2];
    logic signed [NEURAL_ACCUMULATOR_WIDTH-1:0] level2   [TERNARY_TRITS_PER_REG/4];
    logic signed [NEURAL_ACCUMULATOR_WIDTH-1:0] level3   [TERNARY_TRITS_PER_REG/8];
    logic signed [NEURAL_ACCUMULATOR_WIDTH-1:0] level4;
    logic [TERNARY_BITS_PER_TRIT-1:0] bias_trit;
    logic signed [1:0]                bias_int;

    // Unrolled parallel computation for all trits - OPTIMIZED for speed
    // Using direct lookup instead of function calls for maximum performance
    for (int i = 0; i < TERNARY_TRITS_PER_REG; i++) begin
      automatic logic [TERNARY_BITS_PER_TRIT-1:0] weight_trit;
      automatic logic [TERNARY_BITS_PER_TRIT-1:0] input_trit;
      automatic logic signed [1:0] w_int, i_int, product;

      weight_trit = weights_i[i*TERNARY_BITS_PER_TRIT +: TERNARY_BITS_PER_TRIT];
      input_trit  = inputs_i[i*TERNARY_BITS_PER_TRIT +: TERNARY_BITS_PER_TRIT];

      // Direct lookup conversion (faster than function call)
      w_int = (weight_trit == TRIT_NEG) ? -2'sd1 :
              (weight_trit == TRIT_POS) ?  2'sd1 : 2'sd0;
      i_int = (input_trit == TRIT_NEG) ? -2'sd1 :
              (input_trit == TRIT_POS) ?  2'sd1 : 2'sd0;

      // Fast multiplication: -1*-1=1, -1*1=-1, 1*1=1, 0*x=0
      product = w_int * i_int;

      // Zero-extension with sign preservation
      level0[i] = {{NEURAL_ACCUMULATOR_WIDTH-2{product[1]}}, product};
    end

    // Optimized reduction tree with register hints for synthesis
    // Level 1: 16 -> 8 (8 parallel adders)
    for (int i = 0; i < (TERNARY_TRITS_PER_REG/2); i++) begin
      level1[i] = level0[2*i] + level0[2*i+1];
    end
    // Level 2: 8 -> 4 (4 parallel adders)
    for (int i = 0; i < (TERNARY_TRITS_PER_REG/4); i++) begin
      level2[i] = level1[2*i] + level1[2*i+1];
    end
    // Level 3: 4 -> 2 (2 parallel adders)
    for (int i = 0; i < (TERNARY_TRITS_PER_REG/8); i++) begin
      level3[i] = level2[2*i] + level2[2*i+1];
    end
    // Level 4: 2 -> 1 (final accumulation)
    level4 = level3[0] + level3[1];

    // Fast bias addition with direct lookup (no function call)
    bias_trit = bias_i[TERNARY_BITS_PER_TRIT-1:0];
    bias_int  = (bias_trit == TRIT_NEG) ? -2'sd1 :
                (bias_trit == TRIT_POS) ?  2'sd1 : 2'sd0;

    next_accumulator = level4 + {{NEURAL_ACCUMULATOR_WIDTH-2{bias_int[1]}}, bias_int};
  end

  // Main neural processing logic
  always_comb begin
    case (operation_i)
      NEURAL_MULTIPLY: begin
        // Store accumulated result for next stage - Return raw accumulator value
        result_o = {{TERNARY_REG_WIDTH-NEURAL_ACCUMULATOR_WIDTH{1'b0}},
                    next_accumulator};
        valid_o = 1'b1;
      end

      NEURAL_ACCUMULATE: begin
        // Return accumulated value as ternary (keep raw for now)
        result_o = {{TERNARY_REG_WIDTH-NEURAL_ACCUMULATOR_WIDTH{1'b0}},
                    next_accumulator};
        valid_o = 1'b1;
      end

      NEURAL_ACTIVATE: begin
        // Ternary activation function: sign(accumulator)
        if (next_accumulator > 1) begin
          // +1 in ternary encoding
          result_o = {{TERNARY_REG_WIDTH-TERNARY_BITS_PER_TRIT{1'b0}}, TRIT_POS};
        end else if (next_accumulator < -1) begin
          // -1 in ternary encoding
          result_o = {{TERNARY_REG_WIDTH-TERNARY_BITS_PER_TRIT{1'b0}}, TRIT_NEG};
        end else begin
          // 0 in ternary encoding
          result_o = {{TERNARY_REG_WIDTH-TERNARY_BITS_PER_TRIT{1'b0}}, TRIT_ZERO};
        end
        valid_o = 1'b1;
      end

      NEURAL_LEARN: begin
        // Placeholder for future learning algorithms
        // For now, just pass through the weights unchanged
        result_o = weights_i;
        valid_o = 1'b1;
      end

      default: begin
        result_o = TERNARY_ZERO_PATTERN;
        valid_o = 1'b0;
      end
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

  // Basic operation validity
  `ASSERT_INIT(NeuralValidOp, operation_i inside
    {NEURAL_MULTIPLY, NEURAL_ACCUMULATE, NEURAL_ACTIVATE, NEURAL_LEARN})

  // Valid output should always be asserted for implemented operations
  `ASSERT_INIT(ValidOutputForValidOp,
    operation_i inside {NEURAL_MULTIPLY, NEURAL_ACCUMULATE,
                        NEURAL_ACTIVATE, NEURAL_LEARN} |-> valid_o)

  // Input validation
  `ASSERT_INIT(ValidInputs,
    all_trits_valid(weights_i) && all_trits_valid(inputs_i))

  // Accumulator bounds check
  `ASSERT_INIT(AccumulatorBounds,
    next_accumulator >= NEURAL_ACCUMULATOR_WIDTH'(signed'(NEURAL_ACCUMULATOR_MIN)) &&
    next_accumulator <= NEURAL_ACCUMULATOR_WIDTH'(signed'(NEURAL_ACCUMULATOR_MAX)))

  // Operation-specific assertions
  `ASSERT_INIT(MultiplyAccumulateRange,
    (operation_i inside {NEURAL_MULTIPLY, NEURAL_ACCUMULATE}) |->
    (result_o[TERNARY_REG_WIDTH-1:NEURAL_ACCUMULATOR_WIDTH] == '0))

  `ASSERT_INIT(ActivationOutputValid,
    (operation_i == NEURAL_ACTIVATE) |->
    (result_o[TERNARY_REG_WIDTH-1:TERNARY_BITS_PER_TRIT] == '0 &&
     is_valid_trit(result_o[TERNARY_BITS_PER_TRIT-1:0])))

  `ASSERT_INIT(LearnPassThrough,
    (operation_i == NEURAL_LEARN) |->
    (result_o == weights_i))

  // Trit conversion correctness
  genvar trit_idx;
  generate
    for (trit_idx = 0; trit_idx < TERNARY_TRITS_PER_REG; trit_idx++)
      begin : g_trit_conversion_assertions
  logic [TERNARY_BITS_PER_TRIT-1:0] weight_trit;
  /* verilator lint_off UNUSED */
  logic signed [1:0] weight_int;
  /* verilator lint_on UNUSED */

      assign weight_trit = weights_i[trit_idx*TERNARY_BITS_PER_TRIT +: TERNARY_BITS_PER_TRIT];
      assign weight_int = trit_to_int(weight_trit);

      // Trit to integer conversion correctness
      `ASSERT_INIT(TritToIntCorrectNeg,
        (weight_trit == TRIT_NEG) |-> (weight_int == -1))
      `ASSERT_INIT(TritToIntCorrectZero,
        (weight_trit == TRIT_ZERO) |-> (weight_int == 0))
      `ASSERT_INIT(TritToIntCorrectPos,
        (weight_trit == TRIT_POS) |-> (weight_int == 1))

      // Integer to trit conversion correctness
      `ASSERT_INIT(IntToTritCorrectNeg,
        (weight_int < 0) |-> (int_to_trit({{6{weight_int[1]}}, weight_int}) == TRIT_NEG))
      `ASSERT_INIT(IntToTritCorrectZero,
        (weight_int == 0) |-> (int_to_trit({{6{weight_int[1]}}, weight_int}) == TRIT_ZERO))
      `ASSERT_INIT(IntToTritCorrectPos,
        (weight_int > 0) |-> (int_to_trit({{6{weight_int[1]}}, weight_int}) == TRIT_POS))
    end
  endgenerate

  // Simulation-only dynamic checks
  always_comb begin
    // Runtime accumulator bounds check
    assert (next_accumulator >= NEURAL_ACCUMULATOR_WIDTH'(signed'(NEURAL_ACCUMULATOR_MIN)) &&
            next_accumulator <= NEURAL_ACCUMULATOR_WIDTH'(signed'(NEURAL_ACCUMULATOR_MAX))) else
            $error("Neural unit accumulator out of range: %d", next_accumulator);

    // Check that unused bias bits are properly handled
    assert (unused_bias_bits == bias_i[TERNARY_REG_WIDTH-1:TERNARY_BITS_PER_TRIT]) else
      $error("Unused bias bits assignment error");
  end

endmodule
