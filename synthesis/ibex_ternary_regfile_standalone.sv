// Standalone Ternary Register File for Synthesis
// Copyright lowRISC contributors.
// Copyright 2025 MHX Neural.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/**
 * Ternary Register File for MHX Neural T1 (Synthesis Version)
 *
 * Provides storage for ternary values in a special register file.
 * Each register stores 16 ternary digits (trits) using 32 bits.
 */

module ibex_ternary_regfile_synth #(
  parameter int unsigned ADDR_WIDTH = 5,
  parameter int unsigned DATA_WIDTH = 32
) (
  input logic                      clk_i,
  input logic                      rst_ni,
  
  // Read port A
  input  logic [ADDR_WIDTH-1:0]    raddr_a_i,
  output logic [DATA_WIDTH-1:0]    rdata_a_o,
  
  // Read port B
  input  logic [ADDR_WIDTH-1:0]    raddr_b_i,
  output logic [DATA_WIDTH-1:0]    rdata_b_o,
  
  // Write port
  input  logic [ADDR_WIDTH-1:0]    waddr_i,
  input  logic [DATA_WIDTH-1:0]    wdata_i,
  input  logic                     we_i
);

  localparam int unsigned NUM_WORDS = 2**ADDR_WIDTH;

  logic [DATA_WIDTH-1:0] rf_reg [NUM_WORDS];

  // Write operation
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      for (int unsigned i = 0; i < NUM_WORDS; i++) begin
        rf_reg[i] <= '0;
      end
    end else if (we_i && (waddr_i != '0)) begin // x0 is hardwired to 0
      rf_reg[waddr_i] <= wdata_i;
    end
  end

  // Read port A
  always_comb begin
    if (raddr_a_i == '0) begin
      rdata_a_o = '0; // x0 is hardwired to 0
    end else begin
      rdata_a_o = rf_reg[raddr_a_i];
    end
  end

  // Read port B
  always_comb begin
    if (raddr_b_i == '0) begin
      rdata_b_o = '0; // x0 is hardwired to 0
    end else begin
      rdata_b_o = rf_reg[raddr_b_i];
    end
  end

endmodule