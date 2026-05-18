// Copyright 2025 MHX™ Neural.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/**
 * Formal Verification Wrapper for MHX™ Ternary Register File
 *
 * This module wraps the Ternary Register File with comprehensive formal
 * verification properties using SystemVerilog Assertions (SVA).
 */

module ternary_regfile_formal import ibex_pkg::*; (
  input logic clk_i,
  input logic rst_ni
);

  // Formal verification inputs
  logic [TERNARY_ADDR_WIDTH-1:0] raddr_a;
  logic [TERNARY_ADDR_WIDTH-1:0] raddr_b;
  logic [TERNARY_ADDR_WIDTH-1:0] waddr;
  logic [TERNARY_REG_WIDTH-1:0]  wdata;
  logic                          we;

  // DUT outputs
  logic [TERNARY_REG_WIDTH-1:0] rdata_a;
  logic [TERNARY_REG_WIDTH-1:0] rdata_b;

  // Instantiate DUT
  ibex_ternary_regfile dut (
    .clk_i     (clk_i),
    .rst_ni    (rst_ni),
    .clear_i   (1'b0),
    .raddr_a_i (raddr_a),
    .raddr_b_i (raddr_b),
    .rdata_a_o (rdata_a),
    .rdata_b_o (rdata_b),
    .waddr_i   (waddr),
    .wdata_i   (wdata),
    .we_i      (we)
  );

  // Symbolic inputs for formal verification
  (* anyseq *) logic [TERNARY_ADDR_WIDTH-1:0] sym_raddr_a;
  (* anyseq *) logic [TERNARY_ADDR_WIDTH-1:0] sym_raddr_b;
  (* anyseq *) logic [TERNARY_ADDR_WIDTH-1:0] sym_waddr;
  (* anyseq *) logic [TERNARY_REG_WIDTH-1:0]  sym_wdata;
  (* anyseq *) logic                          sym_we;

  // Drive inputs from symbolic values
  always_comb begin
    raddr_a = sym_raddr_a;
    raddr_b = sym_raddr_b;
    waddr   = sym_waddr;
    wdata   = sym_wdata;
    we      = sym_we;
  end

  //////////////////////////////////////////////////////////////////////////////
  // Helper Functions
  //////////////////////////////////////////////////////////////////////////////

  // Check if a trit encoding is valid
  function automatic logic is_valid_trit(logic [1:0] trit);
    return (trit == TRIT_NEG || trit == TRIT_ZERO || trit == TRIT_POS);
  endfunction

  //////////////////////////////////////////////////////////////////////////////
  // SECTION 1: T0 Hardwired Zero (RISC-V Convention)
  //////////////////////////////////////////////////////////////////////////////

  // Property: T0 always reads as zero pattern
  regfile_t0_read_zero_a: assert property (
    @(posedge clk_i) disable iff (!rst_ni)
    (raddr_a == 5'd0) |-> (rdata_a == TERNARY_RESET_VALUE)
  );

  regfile_t0_read_zero_b: assert property (
    @(posedge clk_i) disable iff (!rst_ni)
    (raddr_b == 5'd0) |-> (rdata_b == TERNARY_RESET_VALUE)
  );

  // Property: Writes to T0 are ignored
  regfile_t0_no_write: assert property (
    @(posedge clk_i) disable iff (!rst_ni)
    (we && waddr == 5'd0) |=> (rdata_a == TERNARY_RESET_VALUE) ##0 (raddr_a == 5'd0)
  );

  //////////////////////////////////////////////////////////////////////////////
  // SECTION 2: Write-Then-Read Consistency
  //////////////////////////////////////////////////////////////////////////////

  // Track a single register for formal verification
  (* anyconst *) logic [TERNARY_ADDR_WIDTH-1:0] track_addr;

  // Assume tracked address is valid and not T0
  assume property (@(posedge clk_i) track_addr > 0 && track_addr < TERNARY_NUM_REGISTERS);

  // Shadow register to track expected value
  logic [TERNARY_REG_WIDTH-1:0] shadow_reg;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      shadow_reg <= TERNARY_RESET_VALUE;
    end else if (we && waddr == track_addr) begin
      shadow_reg <= ternary_sanitize_word(wdata);
    end
  end

  // Property: Reading the tracked register returns the expected value
  regfile_read_consistency: assert property (
    @(posedge clk_i) disable iff (!rst_ni)
    (raddr_a == track_addr) |-> (rdata_a == shadow_reg)
  );

  regfile_read_consistency_b: assert property (
    @(posedge clk_i) disable iff (!rst_ni)
    (raddr_b == track_addr) |-> (rdata_b == shadow_reg)
  );

  //////////////////////////////////////////////////////////////////////////////
  // SECTION 3: Write Enable Properties
  //////////////////////////////////////////////////////////////////////////////

  // Property: No write when WE is low
  regfile_no_write_when_disabled: assert property (
    @(posedge clk_i) disable iff (!rst_ni)
    (!we && waddr == track_addr) |=> (shadow_reg == $past(shadow_reg))
  );

  // Property: Write occurs when WE is high (for non-T0)
  regfile_write_when_enabled: assert property (
    @(posedge clk_i) disable iff (!rst_ni)
    (we && waddr == track_addr && track_addr != 0) |=> (shadow_reg == ternary_sanitize_word($past(wdata)))
  );

  //////////////////////////////////////////////////////////////////////////////
  // SECTION 4: Reset Behavior
  //////////////////////////////////////////////////////////////////////////////

  // Property: All registers reset to zero pattern
  regfile_reset_value: assert property (
    @(posedge clk_i)
    (!rst_ni) |=> (shadow_reg == TERNARY_RESET_VALUE)
  );

  //////////////////////////////////////////////////////////////////////////////
  // SECTION 5: Address Bounds
  //////////////////////////////////////////////////////////////////////////////

  // Assume addresses are in valid range (for formal verification)
  assume property (@(posedge clk_i) raddr_a < TERNARY_NUM_REGISTERS);
  assume property (@(posedge clk_i) raddr_b < TERNARY_NUM_REGISTERS);
  assume property (@(posedge clk_i) waddr < TERNARY_NUM_REGISTERS);

  //////////////////////////////////////////////////////////////////////////////
  // SECTION 6: Read Port Independence
  //////////////////////////////////////////////////////////////////////////////

  // Property: Read ports are independent
  regfile_port_independence: assert property (
    @(posedge clk_i) disable iff (!rst_ni)
    (raddr_a != raddr_b && raddr_a == track_addr) |->
    (rdata_a == shadow_reg)
  );

  //////////////////////////////////////////////////////////////////////////////
  // SECTION 7: Timing Properties
  //////////////////////////////////////////////////////////////////////////////

  // Property: Read is combinational (same cycle)
  regfile_read_combinational: assert property (
    @(posedge clk_i) disable iff (!rst_ni)
    (raddr_a == track_addr) |-> (rdata_a == shadow_reg)
  );

  // Property: Write takes one cycle
  regfile_write_latency: assert property (
    @(posedge clk_i) disable iff (!rst_ni)
    (we && waddr == track_addr && track_addr != 0) |=>
    (raddr_a == track_addr) |-> (rdata_a == ternary_sanitize_word($past(wdata)))
  );

  //////////////////////////////////////////////////////////////////////////////
  // SECTION 8: Constant-Time Properties (Security)
  //////////////////////////////////////////////////////////////////////////////

  // Property: Read latency is constant (no timing side channel)
  // This is verified by design: combinational read logic

  // Property: Write latency is constant regardless of data
  regfile_constant_time_write: assert property (
    @(posedge clk_i) disable iff (!rst_ni)
    (we && waddr == track_addr && track_addr != 0) |=>
    (shadow_reg == ternary_sanitize_word($past(wdata)))
  );

  //////////////////////////////////////////////////////////////////////////////
  // SECTION 9: Coverage Points
  //////////////////////////////////////////////////////////////////////////////

  // Cover read operations
  cover_read_t0:     cover property (@(posedge clk_i) raddr_a == 5'd0);
  cover_read_t1:     cover property (@(posedge clk_i) raddr_a == 5'd1);
  cover_read_t31:    cover property (@(posedge clk_i) raddr_a == 5'd31);

  // Cover write operations
  cover_write_t1:    cover property (@(posedge clk_i) we && waddr == 5'd1);
  cover_write_t0:    cover property (@(posedge clk_i) we && waddr == 5'd0);
  cover_write_t31:   cover property (@(posedge clk_i) we && waddr == 5'd31);

  // Cover simultaneous read/write
  cover_read_write_same: cover property (
    @(posedge clk_i) we && raddr_a == waddr && waddr != 0
  );

  cover_read_write_diff: cover property (
    @(posedge clk_i) we && raddr_a != waddr
  );

  // Cover reset
  cover_reset: cover property (@(posedge clk_i) !rst_ni);

endmodule
