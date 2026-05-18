// Copyright lowRISC contributors.
// Copyright 2025 MHX™ Neural.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/**
 * MHX™ Basic Neural Processing Unit
 *
 * Simple neural unit for ternary neural network operations:
 * - Ternary multiply-accumulate (MAC)
 * - Sign activation function
 * - Suitable for inference workloads
 *
 * For advanced features (pipelining, caching, multiple activations),
 * see ibex_neural_unit_enhanced.sv
 */

`include "prim_assert.sv"

module ibex_neural_unit import ibex_pkg::*; (
  input  logic [TERNARY_REG_WIDTH-1:0] weights_i,   // Ternary weights
  input  logic [TERNARY_REG_WIDTH-1:0] inputs_i,    // Ternary inputs
  input  logic [TERNARY_REG_WIDTH-1:0] bias_i,      // Bias value (lower trit used)
  input  neural_op_e                   operation_i, // Neural operation

  output logic [TERNARY_REG_WIDTH-1:0] result_o,    // Neural result
  output logic                         valid_o      // Operation valid
);

  // Accumulator width for MAC operations
  localparam int AccWidth = 10;

  // Internal signals
  logic signed [AccWidth-1:0] accumulator;
  logic signed [AccWidth-1:0] activated;

  // Convert trit encoding to signed integer
  function automatic logic signed [1:0] trit_to_int(logic [1:0] trit);
    case (trit)
      TRIT_NEG:  return -1;
      TRIT_ZERO: return 0;
      TRIT_POS:  return 1;
      default:   return 0;
    endcase
  endfunction

  // Convert signed integer to trit encoding
  function automatic logic [1:0] int_to_trit(logic signed [AccWidth-1:0] val);
    if (val > 0) return TRIT_POS;
    else if (val < 0) return TRIT_NEG;
    else return TRIT_ZERO;
  endfunction

  // Compute saturated ternary addition for learning
  function automatic logic [1:0] sat_trit_add(logic [1:0] a, logic [1:0] b);
    logic signed [AccWidth-1:0] sum;
    logic signed [1:0] a_int, b_int;
    a_int = trit_to_int(a);
    b_int = trit_to_int(b);
    sum = {{AccWidth-2{a_int[1]}}, a_int} + {{AccWidth-2{b_int[1]}}, b_int};
    if (sum > 1) return TRIT_POS;
    else if (sum < -1) return TRIT_NEG;
    // Sign-extend sum to AccWidth bits for int_to_trit function
    else return int_to_trit(AccWidth'(signed'(sum)));
  endfunction

  // Multiply-accumulate logic
  always_comb begin
    logic signed [AccWidth-1:0] mac_result;
    logic [1:0] bias_trit;
    logic signed [AccWidth-1:0] bias_int;

    mac_result = '0;

    // Perform dot product: sum(weights[i] * inputs[i])
    for (int i = 0; i < TERNARY_TRITS_PER_REG; i++) begin
      logic [1:0] w_trit, i_trit;
      logic signed [1:0] w_int, i_int;
      logic signed [AccWidth-1:0] product;

      w_trit = ternary_sanitize_trit(weights_i[i*TERNARY_BITS_PER_TRIT +: TERNARY_BITS_PER_TRIT]);
      i_trit = ternary_sanitize_trit(inputs_i[i*TERNARY_BITS_PER_TRIT +: TERNARY_BITS_PER_TRIT]);

      w_int = trit_to_int(w_trit);
      i_int = trit_to_int(i_trit);

      // Ternary multiplication: result is always in {-1, 0, +1}
      product = AccWidth'(signed'(w_int * i_int));
      mac_result = mac_result + product;
    end

    // Add bias
    bias_trit = ternary_sanitize_trit(bias_i[TERNARY_BITS_PER_TRIT-1:0]);
    begin
      logic signed [1:0] bias_trit_int;
      bias_trit_int = trit_to_int(bias_trit);
      bias_int = {{AccWidth-2{bias_trit_int[1]}}, bias_trit_int};
    end
    accumulator = mac_result + AccWidth'(signed'(bias_int));
  end

  // Activation function (sign)
  always_comb begin
    if (accumulator > 0) begin
      activated = 1;
    end else if (accumulator < 0) begin
      activated = -1;
    end else begin
      activated = 0;
    end
  end

  // Output generation based on operation
  always_comb begin
    result_o = TERNARY_ZERO_PATTERN;
    valid_o = 1'b0;

    case (operation_i)
      NEURAL_MULTIPLY: begin
        // Return raw accumulator as ternary-encoded scalar
        result_o[TERNARY_BITS_PER_TRIT-1:0] = int_to_trit(accumulator);
        valid_o = 1'b1;
      end

      NEURAL_ACCUMULATE: begin
        // Return the saturated accumulator sign as a canonical ternary scalar. The remaining trits
        // stay ternary zero so this result is always safe to write to the ternary register file.
        result_o[TERNARY_BITS_PER_TRIT-1:0] = int_to_trit(accumulator);
        valid_o = 1'b1;
      end

      NEURAL_ACTIVATE: begin
        // Return activated result
        result_o[TERNARY_BITS_PER_TRIT-1:0] = int_to_trit(activated);
        valid_o = 1'b1;
      end

      NEURAL_LEARN: begin
        // Simple weight update: weights + delta using saturating addition
        // For actual learning, use enhanced neural unit
        valid_o = 1'b1;
        for (int i = 0; i < TERNARY_TRITS_PER_REG; i++) begin
          result_o[i*TERNARY_BITS_PER_TRIT +: TERNARY_BITS_PER_TRIT] = sat_trit_add(
            ternary_sanitize_trit(weights_i[i*TERNARY_BITS_PER_TRIT +: TERNARY_BITS_PER_TRIT]),
            ternary_sanitize_trit(inputs_i[i*TERNARY_BITS_PER_TRIT +: TERNARY_BITS_PER_TRIT])
          );
        end
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

  // Valid only for known operations
  `ASSERT(ValidOnlyKnownOps,
    valid_o |-> operation_i inside {NEURAL_MULTIPLY, NEURAL_ACCUMULATE,
                                    NEURAL_ACTIVATE, NEURAL_LEARN})

  // Result is valid ternary encoding (when valid) for every trit.
  generate
    for (genvar assert_trit = 0; assert_trit < TERNARY_TRITS_PER_REG; assert_trit++) begin : gen_result_valid
      `ASSERT(ResultValidTernary,
        valid_o |-> result_o[assert_trit*TERNARY_BITS_PER_TRIT +: TERNARY_BITS_PER_TRIT]
            inside {TRIT_NEG, TRIT_ZERO, TRIT_POS})
    end
  endgenerate

  // Activation output is always ternary (-1, 0, +1)
  `ASSERT(ActivationOutputTernary,
    (operation_i == NEURAL_ACTIVATE && valid_o) |->
    (activated inside {-1, 0, 1}))

  // Accumulator bounded (for 16 MACs, max is 16)
  `ASSERT(AccumulatorBounded,
    valid_o |-> (accumulator >= -16 && accumulator <= 16))

endmodule
