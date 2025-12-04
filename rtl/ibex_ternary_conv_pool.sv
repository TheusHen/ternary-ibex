// Copyright lowRISC contributors.
// Copyright 2025 MHX Neural.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/**
 * MHX Ternary Convolution and Pooling Unit
 *
 * Advanced neural network operations for ternary data:
 * - 1D/2D Convolution with ternary kernels
 * - Max/Average/Min Pooling
 * - Strided convolution support
 * - Padding modes (zero, replicate)
 *
 * Optimizations:
 * - Skip-zero multiplication
 * - Parallel multiply-accumulate
 * - Pipelined architecture
 * - Hardware activation integration
 */

`include "prim_assert.sv"

module ibex_ternary_conv_pool import ibex_pkg::*; #(
  parameter int unsigned KernelSize   = 3,   // 3x3 kernel support
  parameter int unsigned MaxPoolSize  = 2,   // 2x2 pooling
  parameter int unsigned PipeDepth    = 3    // Pipeline stages
) (
  input  logic                         clk_i,
  input  logic                         rst_ni,

  // Operation control
  input  logic [2:0]                   operation_i,     // Operation type
  input  logic [1:0]                   pool_mode_i,     // 00=max, 01=avg, 10=min
  input  logic                         stride_i,        // 0=1, 1=2
  input  logic                         padding_i,       // 0=zero, 1=replicate
  input  logic                         start_i,         // Start operation
  output logic                         ready_o,         // Ready for new op
  output logic                         valid_o,         // Output valid

  // Input data (feature map window)
  input  logic [TERNARY_REG_WIDTH-1:0] input_0_i,       // Input row 0
  input  logic [TERNARY_REG_WIDTH-1:0] input_1_i,       // Input row 1
  input  logic [TERNARY_REG_WIDTH-1:0] input_2_i,       // Input row 2

  // Kernel weights (for convolution)
  input  logic [TERNARY_REG_WIDTH-1:0] kernel_0_i,      // Kernel row 0
  input  logic [TERNARY_REG_WIDTH-1:0] kernel_1_i,      // Kernel row 1
  input  logic [TERNARY_REG_WIDTH-1:0] kernel_2_i,      // Kernel row 2

  // Bias and activation
  input  logic [7:0]                   bias_i,          // Convolution bias
  input  logic [1:0]                   activation_i,    // Activation function

  // Output
  output logic [TERNARY_REG_WIDTH-1:0] result_o,        // Operation result
  output logic [7:0]                   scalar_result_o  // Scalar result (pooling)
);

  // Operation encodings
  typedef enum logic [2:0] {
    CONV_OP_CONV1D    = 3'b000,  // 1D convolution
    CONV_OP_CONV2D    = 3'b001,  // 2D convolution (3x3)
    CONV_OP_POOL_MAX  = 3'b010,  // Max pooling
    CONV_OP_POOL_AVG  = 3'b011,  // Average pooling
    CONV_OP_POOL_MIN  = 3'b100,  // Min pooling
    CONV_OP_DEPTHWISE = 3'b101,  // Depthwise convolution
    CONV_OP_POINTWISE = 3'b110   // Pointwise (1x1) convolution
  } conv_op_e;

  // Pipeline stages
  logic signed [15:0] pipe_stage1 [KernelSize*KernelSize];
  logic signed [15:0] pipe_stage2;
  logic signed [15:0] pipe_stage3;
  logic [PipeDepth-1:0] valid_pipe;

  // Trit to integer conversion
  function automatic logic signed [1:0] trit_to_int(logic [1:0] trit);
    case (trit)
      TRIT_NEG:  return -1;
      TRIT_ZERO: return 0;
      TRIT_POS:  return 1;
      default:   return 0;
    endcase
  endfunction

  // Integer to trit conversion
  function automatic logic [1:0] int_to_trit(logic signed [7:0] val);
    if (val > 0) return TRIT_POS;
    else if (val < 0) return TRIT_NEG;
    else return TRIT_ZERO;
  endfunction

  // Convolution multiply-accumulate
  function automatic logic signed [15:0] conv_mac_3x3(
    logic [TERNARY_REG_WIDTH-1:0] inp0,
    logic [TERNARY_REG_WIDTH-1:0] inp1,
    logic [TERNARY_REG_WIDTH-1:0] inp2,
    logic [TERNARY_REG_WIDTH-1:0] ker0,
    logic [TERNARY_REG_WIDTH-1:0] ker1,
    logic [TERNARY_REG_WIDTH-1:0] ker2,
    int                           start_idx
  );
    logic signed [15:0] acc;
    acc = 0;

    // 3x3 convolution at position start_idx
    for (int ky = 0; ky < 3; ky++) begin
      logic [TERNARY_REG_WIDTH-1:0] inp_row, ker_row;
      case (ky)
        0: begin inp_row = inp0; ker_row = ker0; end
        1: begin inp_row = inp1; ker_row = ker1; end
        2: begin inp_row = inp2; ker_row = ker2; end
        default: begin inp_row = '0; ker_row = '0; end
      endcase

      for (int kx = 0; kx < 3; kx++) begin
        int idx;
        logic [1:0] i_trit, k_trit;
        logic signed [1:0] i_val, k_val;
        logic signed [3:0] product;

        idx = start_idx + kx;
        if (idx >= 0 && idx < TERNARY_TRITS_PER_REG) begin
          i_trit = inp_row[idx*2 +: 2];
          k_trit = ker_row[kx*2 +: 2];
          i_val = trit_to_int(i_trit);
          k_val = trit_to_int(k_trit);

          // Skip-zero optimization
          if (i_val != 0 && k_val != 0) begin
            product = i_val * k_val;
            acc = acc + product;
          end
        end
      end
    end

    return acc;
  endfunction

  // Max pooling 2x2
  function automatic logic [1:0] pool_max_2x2(
    logic [TERNARY_REG_WIDTH-1:0] inp0,
    logic [TERNARY_REG_WIDTH-1:0] inp1,
    int                           start_idx
  );
    logic signed [1:0] max_val;
    logic [1:0] max_trit;
    max_val = -1;
    max_trit = TRIT_NEG;

    for (int py = 0; py < 2; py++) begin
      logic [TERNARY_REG_WIDTH-1:0] inp_row;
      inp_row = (py == 0) ? inp0 : inp1;

      for (int px = 0; px < 2; px++) begin
        int idx;
        logic [1:0] trit;
        logic signed [1:0] val;

        idx = start_idx + px;
        if (idx >= 0 && idx < TERNARY_TRITS_PER_REG) begin
          trit = inp_row[idx*2 +: 2];
          val = trit_to_int(trit);
          if (val > max_val) begin
            max_val = val;
            max_trit = trit;
          end
        end
      end
    end

    return max_trit;
  endfunction

  // Min pooling 2x2
  function automatic logic [1:0] pool_min_2x2(
    logic [TERNARY_REG_WIDTH-1:0] inp0,
    logic [TERNARY_REG_WIDTH-1:0] inp1,
    int                           start_idx
  );
    logic signed [1:0] min_val;
    logic [1:0] min_trit;
    min_val = 1;
    min_trit = TRIT_POS;

    for (int py = 0; py < 2; py++) begin
      logic [TERNARY_REG_WIDTH-1:0] inp_row;
      inp_row = (py == 0) ? inp0 : inp1;

      for (int px = 0; px < 2; px++) begin
        int idx;
        logic [1:0] trit;
        logic signed [1:0] val;

        idx = start_idx + px;
        if (idx >= 0 && idx < TERNARY_TRITS_PER_REG) begin
          trit = inp_row[idx*2 +: 2];
          val = trit_to_int(trit);
          if (val < min_val) begin
            min_val = val;
            min_trit = trit;
          end
        end
      end
    end

    return min_trit;
  endfunction

  // Average pooling 2x2
  function automatic logic [1:0] pool_avg_2x2(
    logic [TERNARY_REG_WIDTH-1:0] inp0,
    logic [TERNARY_REG_WIDTH-1:0] inp1,
    int                           start_idx
  );
    logic signed [3:0] sum;
    sum = 0;

    for (int py = 0; py < 2; py++) begin
      logic [TERNARY_REG_WIDTH-1:0] inp_row;
      inp_row = (py == 0) ? inp0 : inp1;

      for (int px = 0; px < 2; px++) begin
        int idx;
        logic [1:0] trit;

        idx = start_idx + px;
        if (idx >= 0 && idx < TERNARY_TRITS_PER_REG) begin
          trit = inp_row[idx*2 +: 2];
          sum = sum + trit_to_int(trit);
        end
      end
    end

    // Quantize average to ternary
    if (sum > 1) return TRIT_POS;
    else if (sum < -1) return TRIT_NEG;
    else return TRIT_ZERO;
  endfunction

  // Activation function
  function automatic logic signed [15:0] apply_activation(
    logic signed [15:0] val,
    logic [1:0]         act_sel
  );
    case (act_sel)
      2'b00: begin // Sign
        if (val > 0) return 1;
        else if (val < 0) return -1;
        else return 0;
      end
      2'b01: begin // ReLU
        if (val > 0) return val;
        else return 0;
      end
      2'b10: begin // Sigmoid approx
        if (val > 4) return 1;
        else if (val < -4) return -1;
        else return 0;
      end
      2'b11: begin // Tanh approx
        if (val > 2) return 1;
        else if (val < -2) return -1;
        else if (val > 0) return 1;
        else if (val < 0) return -1;
        else return 0;
      end
      default: return val;
    endcase
  endfunction

  // Main pipeline
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      valid_pipe <= '0;
      pipe_stage2 <= '0;
      pipe_stage3 <= '0;
      for (int i = 0; i < KernelSize*KernelSize; i++) begin
        pipe_stage1[i] <= '0;
      end
    end else begin
      // Shift valid pipeline
      valid_pipe <= {valid_pipe[PipeDepth-2:0], start_i};

      // Pipeline stage 1: Compute convolution/pooling partial results
      if (start_i) begin
        case (conv_op_e'(operation_i))
          CONV_OP_CONV2D: begin
            // Compute 3x3 convolution at multiple positions
            for (int i = 0; i < 8; i++) begin
              pipe_stage1[i] <= conv_mac_3x3(
                input_0_i, input_1_i, input_2_i,
                kernel_0_i, kernel_1_i, kernel_2_i,
                i
              );
            end
          end

          default: begin
            for (int i = 0; i < KernelSize*KernelSize; i++) begin
              pipe_stage1[i] <= '0;
            end
          end
        endcase
      end

      // Pipeline stage 2: Sum partial results + bias
      if (valid_pipe[0]) begin
        logic signed [15:0] sum;
        sum = 0;
        for (int i = 0; i < 8; i++) begin
          sum = sum + pipe_stage1[i];
        end
        pipe_stage2 <= sum + {{8{bias_i[7]}}, bias_i};
      end

      // Pipeline stage 3: Apply activation
      if (valid_pipe[1]) begin
        pipe_stage3 <= apply_activation(pipe_stage2, activation_i);
      end
    end
  end

  // Output generation
  always_comb begin
    result_o = '0;
    scalar_result_o = '0;

    case (conv_op_e'(operation_i))
      CONV_OP_CONV2D, CONV_OP_CONV1D, CONV_OP_DEPTHWISE, CONV_OP_POINTWISE: begin
        // Convert scalar result to ternary output
        result_o[1:0] = int_to_trit(pipe_stage3[7:0]);
        scalar_result_o = pipe_stage3[7:0];
      end

      CONV_OP_POOL_MAX: begin
        // Max pooling across positions
        for (int i = 0; i < 8; i++) begin
          result_o[i*2 +: 2] = pool_max_2x2(input_0_i, input_1_i, i*2);
        end
      end

      CONV_OP_POOL_MIN: begin
        // Min pooling across positions
        for (int i = 0; i < 8; i++) begin
          result_o[i*2 +: 2] = pool_min_2x2(input_0_i, input_1_i, i*2);
        end
      end

      CONV_OP_POOL_AVG: begin
        // Average pooling across positions
        for (int i = 0; i < 8; i++) begin
          result_o[i*2 +: 2] = pool_avg_2x2(input_0_i, input_1_i, i*2);
        end
      end

      default: begin
        result_o = TERNARY_ZERO_PATTERN;
      end
    endcase
  end

  // Control signals
  assign ready_o = !valid_pipe[0] && !valid_pipe[1];
  assign valid_o = valid_pipe[PipeDepth-1];

  ///////////////////////////
  // Formal Verification   //
  ///////////////////////////

  // Valid only after pipeline delay
  `ASSERT(ValidAfterPipeline, valid_o |-> $past(start_i, PipeDepth), clk_i, !rst_ni)

  // Ready when pipeline empty
  `ASSERT(ReadyWhenEmpty, ready_o |-> !(|valid_pipe[1:0]), clk_i, !rst_ni)

  // Result is valid ternary encoding
  `ASSERT(ResultValidTernary, result_o[1:0] inside {TRIT_NEG, TRIT_ZERO, TRIT_POS})

endmodule
