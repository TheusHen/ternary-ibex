// Copyright lowRISC contributors.
// Copyright 2025 MHX Neural.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/**
 * Simple GPIO Controller for MHX Simple System
 *
 * Provides basic GPIO functionality for controlling LEDs and reading switches
 * Memory mapped interface at base address + offsets:
 * 0x00: GPIO_OUT - Output data register
 * 0x04: GPIO_IN  - Input data register (read-only)
 * 0x08: GPIO_DIR - Direction register (1=output, 0=input)
 */

module gpio_controller (
  input  logic        clk_i,
  input  logic        rst_ni,

  // Bus interface
  input  logic        req_i,
  input  logic        we_i,
  input  logic [3:0]  be_i,
  input  logic [31:0] addr_i,
  input  logic [31:0] wdata_i,
  output logic        rvalid_o,
  output logic [31:0] rdata_o,

  // GPIO pins
  output logic [7:0]  gpio_o,
  input  logic [7:0]  gpio_i
);

  // Register addresses
  localparam logic [31:0] GPIO_OUT_ADDR = 32'h00;
  localparam logic [31:0] GPIO_IN_ADDR  = 32'h04;
  localparam logic [31:0] GPIO_DIR_ADDR = 32'h08;

  // Internal registers
  logic [7:0] gpio_out_reg;
  logic [7:0] gpio_dir_reg;

  // Address decoding
  logic [31:0] word_addr;
  assign word_addr = {addr_i[31:2], 2'b00};

  // Output assignment
  assign gpio_o = gpio_out_reg & gpio_dir_reg; // Only output when direction is set

  // Read logic
  always_comb begin
    rdata_o = 32'h0;
    case (word_addr[7:0])
      GPIO_OUT_ADDR[7:0]: rdata_o = {24'h0, gpio_out_reg};
      GPIO_IN_ADDR[7:0]:  rdata_o = {24'h0, gpio_i};
      GPIO_DIR_ADDR[7:0]: rdata_o = {24'h0, gpio_dir_reg};
      default:            rdata_o = 32'h0;
    endcase
  end

  // Write logic
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      gpio_out_reg <= 8'h0;
      gpio_dir_reg <= 8'h0;
      rvalid_o     <= 1'b0;
    end else begin
      rvalid_o <= req_i;

      if (req_i && we_i) begin
        case (word_addr[7:0])
          GPIO_OUT_ADDR[7:0]: begin
            if (be_i[0]) gpio_out_reg <= wdata_i[7:0];
          end
          GPIO_DIR_ADDR[7:0]: begin
            if (be_i[0]) gpio_dir_reg <= wdata_i[7:0];
          end
          default: begin
            // Read-only or invalid address, no action
          end
        endcase
      end
    end
  end

endmodule