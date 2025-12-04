// Copyright lowRISC contributors.
// Copyright 2025 MHX Neural.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/**
 * MHX Ternary Load/Store Unit Extension
 *
 * Extends the standard load/store unit with native ternary memory operations:
 * - TLW (Ternary Load Word): Load 16 trits from memory
 * - TSW (Ternary Store Word): Store 16 trits to memory
 * - TLB (Ternary Load Burst): Load multiple ternary registers
 * - TSB (Ternary Store Burst): Store multiple ternary registers
 *
 * Features:
 * - Native ternary addressing mode
 * - Automatic alignment handling
 * - Burst transfers for efficiency
 * - Memory-mapped ternary register access
 */

`include "prim_assert.sv"

module ibex_ternary_lsu import ibex_pkg::*; (
  input  logic                         clk_i,
  input  logic                         rst_ni,

  // Ternary instruction interface
  input  logic                         ternary_req_i,      // Ternary memory request
  input  logic                         ternary_we_i,       // Write enable (1=store, 0=load)
  input  logic [31:0]                  ternary_addr_i,     // Memory address
  input  logic [4:0]                   ternary_reg_i,      // Ternary register index
  input  logic [3:0]                   ternary_burst_i,    // Burst length (0=single)
  input  logic [TERNARY_REG_WIDTH-1:0] ternary_wdata_i,    // Write data from treg

  // Ternary register file interface
  output logic [4:0]                   treg_waddr_o,
  output logic [TERNARY_REG_WIDTH-1:0] treg_wdata_o,
  output logic                         treg_we_o,
  output logic [4:0]                   treg_raddr_o,
  input  logic [TERNARY_REG_WIDTH-1:0] treg_rdata_i,

  // Memory interface
  output logic                         mem_req_o,
  output logic [31:0]                  mem_addr_o,
  output logic [31:0]                  mem_wdata_o,
  output logic                         mem_we_o,
  output logic [3:0]                   mem_be_o,
  input  logic                         mem_gnt_i,
  input  logic                         mem_rvalid_i,
  input  logic [31:0]                  mem_rdata_i,
  input  logic                         mem_err_i,

  // Status
  output logic                         busy_o,
  output logic                         done_o,
  output logic                         error_o
);

  // FSM states
  typedef enum logic [2:0] {
    LSU_IDLE,
    LSU_REQUEST,
    LSU_WAIT,
    LSU_BURST_NEXT,
    LSU_DONE,
    LSU_ERROR
  } lsu_state_e;

  lsu_state_e state_q, state_d;

  // Internal registers
  logic [31:0] addr_q, addr_d;
  logic [4:0]  reg_idx_q, reg_idx_d;
  logic [3:0]  burst_cnt_q, burst_cnt_d;
  logic [3:0]  burst_len_q, burst_len_d;
  logic        we_q, we_d;
  logic [TERNARY_REG_WIDTH-1:0] wdata_q, wdata_d;

  // State machine
  always_comb begin
    state_d     = state_q;
    addr_d      = addr_q;
    reg_idx_d   = reg_idx_q;
    burst_cnt_d = burst_cnt_q;
    burst_len_d = burst_len_q;
    we_d        = we_q;
    wdata_d     = wdata_q;

    mem_req_o   = 1'b0;
    mem_addr_o  = '0;
    mem_wdata_o = '0;
    mem_we_o    = 1'b0;
    mem_be_o    = 4'b1111;

    treg_waddr_o = '0;
    treg_wdata_o = '0;
    treg_we_o    = 1'b0;
    treg_raddr_o = reg_idx_q;

    busy_o  = (state_q != LSU_IDLE);
    done_o  = 1'b0;
    error_o = 1'b0;

    case (state_q)
      LSU_IDLE: begin
        if (ternary_req_i) begin
          state_d     = LSU_REQUEST;
          addr_d      = ternary_addr_i;
          reg_idx_d   = ternary_reg_i;
          burst_len_d = ternary_burst_i;
          burst_cnt_d = '0;
          we_d        = ternary_we_i;
          wdata_d     = ternary_wdata_i;
        end
      end

      LSU_REQUEST: begin
        mem_req_o   = 1'b1;
        mem_addr_o  = addr_q;
        mem_we_o    = we_q;

        if (we_q) begin
          // Store: get data from ternary register
          mem_wdata_o  = treg_rdata_i;
          treg_raddr_o = reg_idx_q;
        end

        if (mem_gnt_i) begin
          state_d = LSU_WAIT;
        end
      end

      LSU_WAIT: begin
        if (mem_rvalid_i) begin
          if (mem_err_i) begin
            state_d = LSU_ERROR;
          end else begin
            if (!we_q) begin
              // Load: write data to ternary register
              treg_waddr_o = reg_idx_q;
              treg_wdata_o = mem_rdata_i;
              treg_we_o    = 1'b1;
            end

            // Check if burst continues
            if (burst_cnt_q < burst_len_q) begin
              state_d     = LSU_BURST_NEXT;
              burst_cnt_d = burst_cnt_q + 1;
              addr_d      = addr_q + 4;
              reg_idx_d   = reg_idx_q + 1;
            end else begin
              state_d = LSU_DONE;
            end
          end
        end
      end

      LSU_BURST_NEXT: begin
        // Prepare next burst transfer
        state_d = LSU_REQUEST;
        if (we_q) begin
          treg_raddr_o = reg_idx_q;
          wdata_d      = treg_rdata_i;
        end
      end

      LSU_DONE: begin
        done_o  = 1'b1;
        state_d = LSU_IDLE;
      end

      LSU_ERROR: begin
        error_o = 1'b1;
        state_d = LSU_IDLE;
      end

      default: begin
        state_d = LSU_IDLE;
      end
    endcase
  end

  // State register
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      state_q     <= LSU_IDLE;
      addr_q      <= '0;
      reg_idx_q   <= '0;
      burst_cnt_q <= '0;
      burst_len_q <= '0;
      we_q        <= 1'b0;
      wdata_q     <= '0;
    end else begin
      state_q     <= state_d;
      addr_q      <= addr_d;
      reg_idx_q   <= reg_idx_d;
      burst_cnt_q <= burst_cnt_d;
      burst_len_q <= burst_len_d;
      we_q        <= we_d;
      wdata_q     <= wdata_d;
    end
  end

  ///////////////////////////
  // Formal Verification   //
  ///////////////////////////

  // Memory request only in REQUEST state
  `ASSERT(MemReqOnlyInRequest, mem_req_o |-> (state_q == LSU_REQUEST), clk_i, !rst_ni)

  // Ternary register write only on load completion
  `ASSERT(TregWeOnlyOnLoad, treg_we_o |-> (!we_q && mem_rvalid_i), clk_i, !rst_ni)

  // Burst counter bounded
  `ASSERT(BurstCountBounded, burst_cnt_q <= burst_len_q, clk_i, !rst_ni)

  // Register index valid
  `ASSERT(RegIdxValid, reg_idx_q < TERNARY_NUM_REGISTERS, clk_i, !rst_ni)

  // Done and error mutually exclusive
  `ASSERT(DoneErrorExclusive, !(done_o && error_o), clk_i, !rst_ni)

  // Idle after done/error
  `ASSERT(IdleAfterDone, done_o |=> (state_q == LSU_IDLE), clk_i, !rst_ni)
  `ASSERT(IdleAfterError, error_o |=> (state_q == LSU_IDLE), clk_i, !rst_ni)

endmodule
