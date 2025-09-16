// Copyright lowRISC contributors.
// Copyright 2025 MHX Neural.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/**
 * FPGA Top-level for MHX Simple System
 *
 * This module provides the top-level interface for running the MHX Simple System
 * on FPGA hardware. It includes clock generation, reset logic, and external
 * interfaces for GPIO and UART.
 */

module mhx_fpga_top (
  // Clock and reset
  input  logic clk_100mhz_i,
  input  logic rst_btn_ni,

  // GPIO interfaces
  output logic [3:0] led_o,
  input  logic [3:0] btn_i,
  input  logic [3:0] sw_i,

  // UART interface
  output logic uart_tx_o,
  input  logic uart_rx_i
);

  // Clock generation - use 50MHz for the MHX system
  logic clk_50mhz;
  logic clk_locked;
  
  clk_wiz_0 u_clk_wiz (
    .clk_out1(clk_50mhz),
    .reset(~rst_btn_ni),
    .locked(clk_locked),
    .clk_in1(clk_100mhz_i)
  );

  // Reset generation
  logic rst_n;
  logic [7:0] reset_counter;
  
  always_ff @(posedge clk_50mhz or negedge clk_locked) begin
    if (!clk_locked) begin
      reset_counter <= 8'h00;
      rst_n <= 1'b0;
    end else begin
      if (reset_counter != 8'hFF) begin
        reset_counter <= reset_counter + 1;
        rst_n <= 1'b0;
      end else begin
        rst_n <= rst_btn_ni;
      end
    end
  end

  // GPIO interface mapping
  logic [7:0] mhx_gpio_o;
  logic [7:0] mhx_gpio_i;
  
  // Map FPGA pins to MHX GPIO
  assign led_o = mhx_gpio_o[3:0];
  assign mhx_gpio_i = {sw_i, btn_i};

  // MHX Simple System instance
  mhx_simple_system #(
    .RV32E           (1'b0),
    .RV32M           (ibex_pkg::RV32MFast),
    .RV32B           (ibex_pkg::RV32BNone),
    .RegFile         (ibex_pkg::RegFileFF),
    .BranchTargetALU (1'b1),
    .WritebackStage  (1'b1),
    .ICache          (1'b0),
    .ICacheECC       (1'b0),
    .SecureIbex      (1'b0),
    .PMPEnable       (1'b0),
    .PMPNumRegions   (4),
    .SRAMInitFile    ("firmware.vmem")
  ) u_mhx_system (
    .IO_CLK  (clk_50mhz),
    .IO_RST_N(rst_n),
    
    .gpio_o  (mhx_gpio_o),
    .gpio_i  (mhx_gpio_i),
    
    .uart_tx_o(uart_tx_o),
    .uart_rx_i(uart_rx_i)
  );

endmodule