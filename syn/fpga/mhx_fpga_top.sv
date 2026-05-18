// Copyright 2025 MHX™ Neural.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/**
 * MHX™ Ternary Extension - FPGA Demo Top Module
 *
 * Demonstrates the MHX™ ternary processing capabilities on FPGA.
 * Target: Digilent Arty A7-35T
 *
 * Features:
 * - LED display of ternary register contents
 * - Button-controlled ternary operations
 * - UART interface for host communication
 * - Simple neural network inference demo
 */

module mhx_fpga_top (
  // Clock and Reset
  input  logic        clk_100mhz_i,   // 100 MHz system clock
  input  logic        rst_n_i,        // Active-low reset (directly from button)

  // LEDs
  output logic [3:0]  led_o,          // 4 green LEDs
  output logic [11:0] led_rgb_o,      // 4 RGB LEDs (accent display)

  // Buttons
  input  logic [3:0]  btn_i,          // 4 push buttons

  // Switches
  input  logic [3:0]  sw_i,           // 4 DIP switches

  // UART
  input  logic        uart_rx_i,      // UART receive
  output logic        uart_tx_o,      // UART transmit

  // Seven-segment display (accent info)
  output logic [7:0]  seg_o,          // Segment cathodes
  output logic [3:0]  an_o            // Digit anodes
);

  import ibex_pkg::*;

  //////////////////////////////////////////////////////////////////////////////
  // Clock and Reset
  //////////////////////////////////////////////////////////////////////////////

  logic clk_50mhz;
  logic rst_n_sync;
  logic [2:0] rst_sync;

  // Simple clock divider (100 MHz -> 50 MHz)
  always_ff @(posedge clk_100mhz_i or negedge rst_n_i) begin
    if (!rst_n_i) begin
      clk_50mhz <= 1'b0;
    end else begin
      clk_50mhz <= ~clk_50mhz;
    end
  end

  // Reset synchronizer
  always_ff @(posedge clk_50mhz or negedge rst_n_i) begin
    if (!rst_n_i) begin
      rst_sync <= 3'b000;
    end else begin
      rst_sync <= {rst_sync[1:0], 1'b1};
    end
  end
  assign rst_n_sync = rst_sync[2];

  //////////////////////////////////////////////////////////////////////////////
  // Ternary Extension Modules
  //////////////////////////////////////////////////////////////////////////////

  // Ternary Register File
  logic [TERNARY_ADDR_WIDTH-1:0] ternary_raddr_a;
  logic [TERNARY_ADDR_WIDTH-1:0] ternary_raddr_b;
  logic [TERNARY_REG_WIDTH-1:0]  ternary_rdata_a;
  logic [TERNARY_REG_WIDTH-1:0]  ternary_rdata_b;
  logic [TERNARY_ADDR_WIDTH-1:0] ternary_waddr;
  logic [TERNARY_REG_WIDTH-1:0]  ternary_wdata;
  logic                          ternary_we;

  ibex_ternary_regfile u_ternary_regfile (
    .clk_i     (clk_50mhz),
    .rst_ni    (rst_n_sync),
    .clear_i   (1'b0),
    .raddr_a_i (ternary_raddr_a),
    .raddr_b_i (ternary_raddr_b),
    .rdata_a_o (ternary_rdata_a),
    .rdata_b_o (ternary_rdata_b),
    .waddr_i   (ternary_waddr),
    .wdata_i   (ternary_wdata),
    .we_i      (ternary_we)
  );

  // Ternary ALU
  logic [TERNARY_REG_WIDTH-1:0] alu_operand_a;
  logic [TERNARY_REG_WIDTH-1:0] alu_operand_b;
  ternary_op_e                  alu_operator;
  logic [TERNARY_REG_WIDTH-1:0] alu_result;
  logic                         alu_ready;
  logic                         alu_overflow;
  logic [TERNARY_TRITS_PER_REG-1:0] alu_trit_overflow;

  ibex_ternary_alu u_ternary_alu (
    .operand_a_i    (alu_operand_a),
    .operand_b_i    (alu_operand_b),
    .operator_i     (alu_operator),
    .result_o       (alu_result),
    .ready_o        (alu_ready),
    .overflow_o     (alu_overflow),
    .trit_overflow_o(alu_trit_overflow)
  );

  // Neural Unit
  logic [TERNARY_REG_WIDTH-1:0] neural_weights;
  logic [TERNARY_REG_WIDTH-1:0] neural_inputs;
  logic [TERNARY_REG_WIDTH-1:0] neural_bias;
  neural_op_e                   neural_operation;
  logic [TERNARY_REG_WIDTH-1:0] neural_result;
  logic                         neural_valid;

  ibex_neural_unit u_neural_unit (
    .weights_i   (neural_weights),
    .inputs_i    (neural_inputs),
    .bias_i      (neural_bias),
    .operation_i (neural_operation),
    .result_o    (neural_result),
    .valid_o     (neural_valid)
  );

  //////////////////////////////////////////////////////////////////////////////
  // Demo Controller
  //////////////////////////////////////////////////////////////////////////////

  logic [7:0] demo_state;
  logic [31:0] counter;
  logic [3:0] btn_debounced;
  logic [3:0] btn_prev;
  logic [3:0] btn_edge;

  // Button debouncing
  logic [19:0] debounce_cnt [4];
  genvar i;
  generate
    for (i = 0; i < 4; i++) begin : g_debounce
      always_ff @(posedge clk_50mhz or negedge rst_n_sync) begin
        if (!rst_n_sync) begin
          debounce_cnt[i] <= '0;
          btn_debounced[i] <= 1'b0;
        end else begin
          if (btn_i[i] != btn_debounced[i]) begin
            if (debounce_cnt[i] == 20'hFFFFF) begin
              btn_debounced[i] <= btn_i[i];
              debounce_cnt[i] <= '0;
            end else begin
              debounce_cnt[i] <= debounce_cnt[i] + 1;
            end
          end else begin
            debounce_cnt[i] <= '0;
          end
        end
      end
    end
  endgenerate

  // Edge detection
  always_ff @(posedge clk_50mhz or negedge rst_n_sync) begin
    if (!rst_n_sync) begin
      btn_prev <= '0;
    end else begin
      btn_prev <= btn_debounced;
    end
  end
  assign btn_edge = btn_debounced & ~btn_prev;

  //////////////////////////////////////////////////////////////////////////////
  // Demo State Machine
  //////////////////////////////////////////////////////////////////////////////

  // Demo modes (selected by switches)
  // sw[1:0] = 00: Ternary ALU demo
  // sw[1:0] = 01: Neural inference demo
  // sw[1:0] = 10: Register file demo
  // sw[1:0] = 11: Performance counter demo

  localparam logic [1:0] MODE_ALU     = 2'b00;
  localparam logic [1:0] MODE_NEURAL  = 2'b01;
  localparam logic [1:0] MODE_REGFILE = 2'b10;
  localparam logic [1:0] MODE_PERF    = 2'b11;

  logic [1:0] demo_mode;
  assign demo_mode = sw_i[1:0];

  // Demo data
  logic [TERNARY_REG_WIDTH-1:0] demo_operand_a;
  logic [TERNARY_REG_WIDTH-1:0] demo_operand_b;
  logic [2:0] demo_op_select;
  logic [TERNARY_REG_WIDTH-1:0] demo_result;

  always_ff @(posedge clk_50mhz or negedge rst_n_sync) begin
    if (!rst_n_sync) begin
      demo_operand_a <= TERNARY_ZERO_PATTERN;
      demo_operand_b <= TERNARY_ZERO_PATTERN;
      demo_op_select <= 3'b000;
      demo_result    <= '0;
      demo_state     <= 8'd0;
      counter        <= '0;

      // Register file control
      ternary_raddr_a <= '0;
      ternary_raddr_b <= '0;
      ternary_waddr   <= '0;
      ternary_wdata   <= TERNARY_ZERO_PATTERN;
      ternary_we      <= 1'b0;

      // Neural unit control
      neural_weights   <= TERNARY_ZERO_PATTERN;
      neural_inputs    <= TERNARY_ZERO_PATTERN;
      neural_bias      <= TERNARY_ZERO_PATTERN;
      neural_operation <= NEURAL_MULTIPLY;

    end else begin
      // Default assignments
      ternary_we <= 1'b0;

      counter <= counter + 1;

      case (demo_mode)
        MODE_ALU: begin
          // ALU Demo Mode
          // BTN0: Cycle through operations
          // BTN1: Increment operand A (first trit)
          // BTN2: Increment operand B (first trit)
          // BTN3: Execute operation

          if (btn_edge[0]) begin
            demo_op_select <= demo_op_select + 1;
          end

          if (btn_edge[1]) begin
            // Cycle first trit of operand A: 00 -> 01 -> 10 -> 00
            case (demo_operand_a[1:0])
              TRIT_NEG:  demo_operand_a[1:0] <= TRIT_ZERO;
              TRIT_ZERO: demo_operand_a[1:0] <= TRIT_POS;
              TRIT_POS:  demo_operand_a[1:0] <= TRIT_NEG;
              default:   demo_operand_a[1:0] <= TRIT_ZERO;
            endcase
          end

          if (btn_edge[2]) begin
            case (demo_operand_b[1:0])
              TRIT_NEG:  demo_operand_b[1:0] <= TRIT_ZERO;
              TRIT_ZERO: demo_operand_b[1:0] <= TRIT_POS;
              TRIT_POS:  demo_operand_b[1:0] <= TRIT_NEG;
              default:   demo_operand_b[1:0] <= TRIT_ZERO;
            endcase
          end

          // Connect ALU
          alu_operand_a <= demo_operand_a;
          alu_operand_b <= demo_operand_b;
          alu_operator  <= ternary_op_e'(demo_op_select);
          demo_result   <= alu_result;
        end

        MODE_NEURAL: begin
          // Neural Inference Demo
          // Runs a simple dot product: weights · inputs + bias

          if (btn_edge[0]) begin
            // Set weights to alternating pattern
            neural_weights <= 32'h55555555;  // All zeros
          end

          if (btn_edge[1]) begin
            // Set inputs to all +1
            neural_inputs <= 32'hAAAAAAAA;  // All +1
          end

          if (btn_edge[2]) begin
            // Set bias to +1
            neural_bias <= {30'b0, TRIT_POS};
          end

          if (btn_edge[3]) begin
            // Run activation
            neural_operation <= NEURAL_ACTIVATE;
          end

          demo_result <= neural_result;
        end

        MODE_REGFILE: begin
          // Register File Demo
          // BTN0: Select register (0-15)
          // BTN1: Write pattern to register
          // BTN2: Read from register

          if (btn_edge[0]) begin
            ternary_waddr <= ternary_waddr + 1;
            ternary_raddr_a <= ternary_raddr_a + 1;
          end

          if (btn_edge[1]) begin
            // Write alternating pattern
            ternary_wdata <= 32'hA5A5A5A5;
            ternary_we <= 1'b1;
          end

          demo_result <= ternary_rdata_a;
        end

        MODE_PERF: begin
          // Performance display mode
          // Shows operation counters
          demo_result <= counter;
        end

        default: begin
          demo_result <= '0;
        end
      endcase
    end
  end

  //////////////////////////////////////////////////////////////////////////////
  // LED Output
  //////////////////////////////////////////////////////////////////////////////

  // Map ternary result to LEDs
  // LED[0]: First trit of result (-1=off, 0=dim, +1=on)
  // LED[1]: Overflow indicator
  // LED[2]: Neural valid
  // LED[3]: Mode indicator

  always_comb begin
    led_o[0] = (demo_result[1:0] == TRIT_POS);
    led_o[1] = (demo_mode == MODE_ALU) ? alu_overflow : 1'b0;
    led_o[2] = (demo_mode == MODE_NEURAL) ? neural_valid : 1'b0;
    led_o[3] = counter[25];  // Heartbeat
  end

  // RGB LEDs show first 4 trits of result
  // Red = -1, Green = +1, Off = 0
  always_comb begin
    led_rgb_o = 12'h000;
    for (int t = 0; t < 4; t++) begin
      case (demo_result[t*2 +: 2])
        TRIT_NEG:  led_rgb_o[t*3 +: 3] = 3'b100;  // Red
        TRIT_ZERO: led_rgb_o[t*3 +: 3] = 3'b000;  // Off
        TRIT_POS:  led_rgb_o[t*3 +: 3] = 3'b010;  // Green
        default:   led_rgb_o[t*3 +: 3] = 3'b001;  // Blue (invalid)
      endcase
    end
  end

  //////////////////////////////////////////////////////////////////////////////
  // Seven-Segment Display
  //////////////////////////////////////////////////////////////////////////////

  // Display mode and operation info
  logic [15:0] display_value;
  logic [1:0] digit_select;

  assign digit_select = counter[17:16];
  assign display_value = {6'b0, demo_mode, 5'b0, demo_op_select};

  // Seven-segment decoder
  function automatic logic [6:0] seg_decode(input logic [3:0] hex);
    case (hex)
      4'h0: return 7'b1000000;
      4'h1: return 7'b1111001;
      4'h2: return 7'b0100100;
      4'h3: return 7'b0110000;
      4'h4: return 7'b0011001;
      4'h5: return 7'b0010010;
      4'h6: return 7'b0000010;
      4'h7: return 7'b1111000;
      4'h8: return 7'b0000000;
      4'h9: return 7'b0010000;
      4'hA: return 7'b0001000;
      4'hB: return 7'b0000011;
      4'hC: return 7'b1000110;
      4'hD: return 7'b0100001;
      4'hE: return 7'b0000110;
      4'hF: return 7'b0001110;
      default: return 7'b1111111;
    endcase
  endfunction

  always_comb begin
    an_o = 4'b1111;
    an_o[digit_select] = 1'b0;
    seg_o[6:0] = seg_decode(display_value[digit_select*4 +: 4]);
    seg_o[7] = 1'b1;  // Decimal point off
  end

  //////////////////////////////////////////////////////////////////////////////
  // UART (Stub - for future expansion)
  //////////////////////////////////////////////////////////////////////////////

  assign uart_tx_o = 1'b1;  // Idle high

endmodule
