// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/**
 * Neural Processing Unit for MHX Core
 *
 * Specialized unit for ternary neural network operations:
 * - Weight × Input multiplication
 * - Accumulation of products
 * - Ternary activation functions
 * - Learning/weight update operations
 */

`include "prim_assert.sv"

module ibex_neural_unit import ibex_pkg::*; (
  input  logic        clk_i,
  input  logic        rst_ni,

  // Operands
  input  logic [31:0] weights_i,    // 16 ternary weights
  input  logic [31:0] inputs_i,     // 16 ternary inputs
  input  logic [31:0] bias_i,       // Bias value (encoded as immediate)
  input  neural_op_e  operation_i,

  // Results
  output logic [31:0] result_o,
  output logic        valid_o
);

  // Internal accumulator for neural computations
  // Can hold sum of 16 trits: range [-16, +16] → needs 6 bits signed
  logic signed [7:0] accumulator;
  logic signed [7:0] next_accumulator;

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

  // Ternary multiply-accumulate for neural computation
  always_comb begin
    next_accumulator = 0;
    // Multiply all weight-input pairs and accumulate
    for (int i = 0; i < 16; i++) begin
      logic [1:0] weight;
      logic [1:0] input_val;
      logic signed [1:0] weight_int;
      logic signed [1:0] input_int;
      logic signed [3:0] product;
      
      weight = weights_i[i*2+1:i*2];
      input_val = inputs_i[i*2+1:i*2];
      weight_int = trit_to_int(weight);
      input_int = trit_to_int(input_val);
      product = weight_int * input_int;
      next_accumulator += product;
    end
    // Add bias (extract from immediate, assuming first trit is bias)
    begin
      logic [1:0] bias_trit;
      logic signed [1:0] bias_int;
      bias_trit = bias_i[1:0];
      bias_int = trit_to_int(bias_trit);
      next_accumulator += bias_int;
    end
  end

  // Main neural processing logic
  always_comb begin
    case (operation_i)
      NEURAL_MULTIPLY: begin
        // Store accumulated result for next stage
        accumulator = next_accumulator;
        result_o = {24'h0, accumulator};  // Return raw accumulator value
        valid_o = 1'b1;
      end

      NEURAL_ACCUMULATE: begin
        // Return accumulated value as ternary (keep raw for now)
        accumulator = next_accumulator;
        result_o = {24'h0, accumulator};
        valid_o = 1'b1;
      end

      NEURAL_ACTIVATE: begin
        // Ternary activation function: sign(accumulator)
        accumulator = next_accumulator;

        if (accumulator > 1) begin
          result_o = {30'h0, TRIT_POS}; // +1 in ternary encoding
        end else if (accumulator < -1) begin
          result_o = {30'h0, TRIT_NEG}; // -1 in ternary encoding
        end else begin
          result_o = {30'h0, TRIT_ZERO}; // 0 in ternary encoding
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
        result_o = 32'h0;
        valid_o = 1'b0;
      end
    endcase
  end

  // Saturation logic for accumulator overflow
  always_comb begin
    // Clamp accumulator to valid range [-16, +16]
    if (next_accumulator > 16) begin
      accumulator = 16;
    end else if (next_accumulator < -16) begin
      accumulator = -16;
    end else begin
      accumulator = next_accumulator;
    end
  end

  // Assertions for debugging
  `ASSERT(NeuralValidOp, operation_i >= NEURAL_MULTIPLY && operation_i <= NEURAL_LEARN,
          clk_i, !rst_ni)
  `ASSERT(AccumulatorRange, accumulator >= -16 && accumulator <= 16, clk_i, !rst_ni)

endmodule
