// Standalone Neural Unit for Synthesis
// Copyright lowRISC contributors.
// Copyright 2025 MHX Neural.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/**
 * Neural Processing Unit for MHX Neural T1 (Synthesis Version)
 *
 * Specialized unit for ternary neural network operations:
 * - Weight × Input multiplication
 * - Accumulation of products
 * - Ternary activation functions
 */

typedef enum logic [1:0] {
  NEURAL_MULTIPLY   = 2'b00,
  NEURAL_ACCUMULATE = 2'b01,
  NEURAL_ACTIVATE   = 2'b10
} neural_op_e;

module ibex_neural_unit_synth (
  input  logic [31:0] weights_i,    // 16 ternary weights
  input  logic [31:0] inputs_i,     // 16 ternary inputs
  input  logic [31:0] bias_i,       // Bias value
  input  neural_op_e  operation_i,

  output logic [31:0] result_o,
  output logic        valid_o
);

  // Trit decoding function
  function automatic logic signed [1:0] decode_trit(input logic [1:0] trit);
    case (trit)
      2'b00: return -1; // -1
      2'b01: return  0; // 0
      2'b10: return  1; // +1
      default: return 0; // Invalid -> 0
    endcase
  endfunction

  // Trit encoding function
  function automatic logic [1:0] encode_trit(input logic signed [1:0] value);
    case (value)
      -1: return 2'b00; // -1
       0: return 2'b01; // 0
       1: return 2'b10; // +1
      default: return 2'b01; // Default to 0
    endcase
  endfunction

  // Activation function
  function automatic logic [1:0] ternary_activate(input logic signed [7:0] value);
    if (value > 0) return 2'b10;      // +1
    else if (value < 0) return 2'b00; // -1
    else return 2'b01;                // 0
  endfunction

  // Neural operations
  always_comb begin
    result_o = 32'h0;
    valid_o = 1'b1;

    case (operation_i)
      NEURAL_MULTIPLY: begin
        // Element-wise multiplication
        for (int i = 0; i < 16; i++) begin
          logic [1:0] weight_trit = weights_i[i*2 +: 2];
          logic [1:0] input_trit = inputs_i[i*2 +: 2];
          
          logic signed [1:0] weight_val = decode_trit(weight_trit);
          logic signed [1:0] input_val = decode_trit(input_trit);
          logic signed [1:0] product = weight_val * input_val;
          
          result_o[i*2 +: 2] = encode_trit(product);
        end
      end

      NEURAL_ACCUMULATE: begin
        // Multiply-accumulate operation
        logic signed [7:0] accumulator = 0;
        
        for (int i = 0; i < 16; i++) begin
          logic [1:0] weight_trit = weights_i[i*2 +: 2];
          logic [1:0] input_trit = inputs_i[i*2 +: 2];
          
          logic signed [1:0] weight_val = decode_trit(weight_trit);
          logic signed [1:0] input_val = decode_trit(input_trit);
          
          accumulator += weight_val * input_val;
        end
        
        // Add bias (only use lowest 2 bits as ternary value)
        logic signed [1:0] bias_val = decode_trit(bias_i[1:0]);
        accumulator += bias_val;
        
        // Store result in lower 8 bits
        result_o[7:0] = accumulator;
        result_o[31:8] = 24'h0;
      end

      NEURAL_ACTIVATE: begin
        // Apply activation function to accumulated result
        logic signed [7:0] input_value = inputs_i[7:0];
        logic [1:0] activated = ternary_activate(input_value);
        
        result_o[1:0] = activated;
        result_o[31:2] = 30'h0;
      end

      default: begin
        result_o = 32'h0;
        valid_o = 1'b0;
      end
    endcase
  end

endmodule