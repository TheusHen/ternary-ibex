// Copyright lowRISC contributors.
// Copyright 2025 MHX Neural.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/**
 * Ternary Register File for MHX Neural T1
 *
 * Features:
 * - 16 ternary registers (T0-T15)
 * - Each register holds 16 trits (32 bits total: 2 bits per trit)
 * - Dual read ports, single write port
 * - Synchronous write, asynchronous read
 */

`include "prim_assert.sv"

module ibex_ternary_regfile import ibex_pkg::*; (
  input  logic        clk_i,
  input  logic        rst_ni,

  // Read ports
  input  logic [3:0]  raddr_a_i,  // 16 ternary registers (4 bits)
  input  logic [3:0]  raddr_b_i,
  output logic [31:0] rdata_a_o,  // 16 trits encoded as 32 bits
  output logic [31:0] rdata_b_o,

  // Write port
  input  logic [3:0]  waddr_i,
  input  logic [31:0] wdata_i,
  input  logic        we_i
);

  // 16 ternary registers, each storing 16 trits (32 bits)
  logic [31:0] ternary_regs [16];

  // Read logic (asynchronous)
  assign rdata_a_o = ternary_regs[raddr_a_i];
  assign rdata_b_o = ternary_regs[raddr_b_i];

  // Write logic (synchronous)
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      // Initialize all ternary registers to zero (all trits = 0)
      for (int i = 0; i < 16; i++) begin
        ternary_regs[i] <= 32'h55555555; // 01010101... = all zeros in ternary
      end
    end else if (we_i) begin
      ternary_regs[waddr_i] <= wdata_i;
    end
  end

  // Assertions for debugging
  `ASSERT(TernaryRegValidAddr_A, raddr_a_i < 16, clk_i, !rst_ni)
  `ASSERT(TernaryRegValidAddr_B, raddr_b_i < 16, clk_i, !rst_ni)
  `ASSERT(TernaryRegValidWrite, !we_i || waddr_i < 16, clk_i, !rst_ni)

endmodule
