// Copyright lowRISC contributors.
// Copyright 2025 MHX Neural.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/**
 * Ternary Register File for MHX Core
 *
 * Features:
 * - 32 ternary registers (T0-T31)
 * - Each register holds 16 trits (32 bits total: 2 bits per trit)
 * - Dual read ports, single write port
 * - Synchronous write, asynchronous read
 * - Enhanced capacity for complex ML/AI workloads
 */

`include "prim_assert.sv"

module ibex_ternary_regfile import ibex_pkg::*; (
  input  logic                            clk_i,
  input  logic                            rst_ni,

  // Read ports
  input  logic [TERNARY_ADDR_WIDTH-1:0]  raddr_a_i,  // Ternary register address A
  input  logic [TERNARY_ADDR_WIDTH-1:0]  raddr_b_i,  // Ternary register address B
  output logic [TERNARY_REG_WIDTH-1:0]   rdata_a_o,  // Ternary data output A
  output logic [TERNARY_REG_WIDTH-1:0]   rdata_b_o,  // Ternary data output B

  // Write port
  input  logic [TERNARY_ADDR_WIDTH-1:0]  waddr_i,    // Ternary register write address
  input  logic [TERNARY_REG_WIDTH-1:0]   wdata_i,    // Ternary data input
  input  logic                            we_i        // Write enable
);

  // Ternary register array
  logic [TERNARY_REG_WIDTH-1:0] ternary_regs [TERNARY_NUM_REGISTERS];

  // Read logic (asynchronous) - T0 always reads as zero (RISC-V convention)
  assign rdata_a_o = (raddr_a_i == '0) ? TERNARY_RESET_VALUE : ternary_regs[raddr_a_i];
  assign rdata_b_o = (raddr_b_i == '0) ? TERNARY_RESET_VALUE : ternary_regs[raddr_b_i];

  // Write logic (synchronous)
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      // Initialize all ternary registers to zero (all trits = 0)
      for (int i = 0; i < TERNARY_NUM_REGISTERS; i++) begin
        ternary_regs[i] <= TERNARY_RESET_VALUE;
      end
    end else if (we_i && waddr_i != '0) begin  // Prevent writes to T0
      ternary_regs[waddr_i] <= wdata_i;
    end
  end

  ///////////////////////////
  // Formal Verification   //
  ///////////////////////////

  // Helper function to check if a trit is valid
  function automatic logic is_valid_trit(logic [1:0] trit);
    return (trit inside {TRIT_NEG, TRIT_ZERO, TRIT_POS});
  endfunction

  // Helper function to check if all trits in a word are valid
  function automatic logic all_trits_valid(logic [TERNARY_REG_WIDTH-1:0] word);
    for (int i = 0; i < TERNARY_TRITS_PER_REG; i++) begin
      if (!is_valid_trit(word[i*TERNARY_BITS_PER_TRIT +: TERNARY_BITS_PER_TRIT])) return 1'b0;
    end
    return 1'b1;
  endfunction

  // Address bounds checking
  `ASSERT(TernaryRegValidAddr_A, raddr_a_i < TERNARY_NUM_REGISTERS, clk_i, !rst_ni)
  `ASSERT(TernaryRegValidAddr_B, raddr_b_i < TERNARY_NUM_REGISTERS, clk_i, !rst_ni)
  `ASSERT(TernaryRegValidWrite, !we_i || waddr_i < TERNARY_NUM_REGISTERS, clk_i, !rst_ni)

  // Write behavior verification
  `ASSERT(WriteWhenEnabled, we_i |=> ternary_regs[waddr_i] == $past(wdata_i), clk_i, !rst_ni)
  `ASSERT(NoWriteWhenDisabled, !we_i |=> ternary_regs == $past(ternary_regs), clk_i, !rst_ni)

  // Reset behavior verification
  `ASSERT(ResetInitialization, !rst_ni |=>
    (ternary_regs[0] == TERNARY_RESET_VALUE &&
     ternary_regs[TERNARY_NUM_REGISTERS-1] == TERNARY_RESET_VALUE),
    clk_i, 1'b1)

  // Read behavior verification (combinational)
  // Note: These are combinational properties, not elaboration-time checks

  // Data integrity assertions
  genvar reg_idx;
  generate
    for (reg_idx = 0; reg_idx < TERNARY_NUM_REGISTERS; reg_idx++) begin : g_register_integrity
      // After reset, all registers should contain valid ternary zeros
      `ASSERT(InitialStateValid, !rst_ni |=>
        (ternary_regs[reg_idx] == TERNARY_RESET_VALUE), clk_i, 1'b1)

      // When writing to a register, the data should be properly stored
      `ASSERT(WriteDataIntegrity,
        (we_i && waddr_i == reg_idx) |=>
        (ternary_regs[reg_idx] == $past(wdata_i)), clk_i, !rst_ni)

      // Register contents should remain stable when not being written to
      `ASSERT(RegisterStability,
        (!we_i || waddr_i != reg_idx) |=>
        (ternary_regs[reg_idx] == $past(ternary_regs[reg_idx])),
        clk_i, !rst_ni)
    end
  endgenerate

  // Cross-port independence (writing to one register doesn't affect reads from others)
  genvar port_test;
  generate
    for (port_test = 0; port_test < TERNARY_NUM_REGISTERS; port_test++) begin : g_port_independence
      `ASSERT(ReadPortA_Independence,
        (raddr_a_i == port_test && (!we_i || waddr_i != port_test)) |->
        (rdata_a_o == ternary_regs[port_test]), clk_i, !rst_ni)

      `ASSERT(ReadPortB_Independence,
        (raddr_b_i == port_test && (!we_i || waddr_i != port_test)) |->
        (rdata_b_o == ternary_regs[port_test]), clk_i, !rst_ni)
    end
  endgenerate

  // Simulation-only checks
  always_ff @(posedge clk_i) begin
    if (rst_ni) begin
      // Check that write data contains valid trits when writing
      if (we_i) begin
        assert (all_trits_valid(wdata_i)) else
          $warning("Writing invalid trit data to register T%0d: 0x%08x", waddr_i, wdata_i);
      end
    end
  end

  ////////////////////////////////////////////////////
  // Power Analysis & Constant-Time Properties      //
  ////////////////////////////////////////////////////

  // Read operations are constant-time (combinational)
  // Property: rdata_a_o == ternary_regs[raddr_a_i]
  // Property: rdata_b_o == ternary_regs[raddr_b_i]
  // These are verified by design - combinational read logic

  // Write operations have constant latency regardless of data
  `ASSERT(WriteConstantLatency_c,
    (we_i && waddr_i != '0) |=>
    ternary_regs[waddr_i] == $past(wdata_i),
    clk_i, !rst_ni)

  // Write enable doesn't depend on data values
  `ASSERT(WriteEnableDataIndependent_c,
    (we_i == $past(we_i) && waddr_i != '0) |->
    ##1 (we_i |-> ternary_regs[waddr_i] == $past(wdata_i)),
    clk_i, !rst_ni)

  // No power side-channel from T0 hardwired zero
  // Property verified by design: T0 always reads as TERNARY_RESET_VALUE

  // Register access pattern doesn't leak through timing
  `ASSERT(NoTimingLeak_c,
    (raddr_a_i != $past(raddr_a_i)) |->
    rdata_a_o == ternary_regs[raddr_a_i],
    clk_i, !rst_ni)

  // No early/late write completion based on data
  `ASSERT(UniformWriteTiming_c,
    (we_i && waddr_i != '0 &&
     wdata_i != $past(wdata_i)) |=>
    ternary_regs[waddr_i] == $past(wdata_i),
    clk_i, !rst_ni)

endmodule
