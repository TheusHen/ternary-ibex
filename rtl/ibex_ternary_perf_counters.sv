// Copyright lowRISC contributors.
// Copyright 2025 MHX Neural.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/**
 * MHX Ternary Performance Counters
 *
 * Provides hardware performance monitoring for ternary and neural operations:
 * - Ternary ALU operation counts
 * - Neural unit operation counts
 * - Cache hit/miss statistics
 * - Sparsity metrics
 * - Cycle counts for ternary operations
 *
 * CSR Addresses (Custom Machine-mode HPM counters):
 * - 0xB00: mhpmcounter_ternary_ops    - Total ternary ALU operations
 * - 0xB01: mhpmcounter_neural_ops     - Total neural operations
 * - 0xB02: mhpmcounter_cache_hits     - Weight cache hits
 * - 0xB03: mhpmcounter_cache_misses   - Weight cache misses
 * - 0xB04: mhpmcounter_sparse_skips   - Zero-skip optimizations
 * - 0xB05: mhpmcounter_overflow_count - Overflow events
 * - 0xB06: mhpmcounter_ternary_cycles - Cycles in ternary ops
 * - 0xB07: mhpmcounter_neural_cycles  - Cycles in neural ops
 */

`include "prim_assert.sv"

module ibex_ternary_perf_counters import ibex_pkg::*; #(
  parameter int unsigned CounterWidth = 32
) (
  input  logic                    clk_i,
  input  logic                    rst_ni,

  // Control signals
  input  logic                    enable_i,          // Global enable
  input  logic                    clear_i,           // Clear all counters

  // Ternary ALU events
  input  logic                    ternary_op_valid_i,    // Ternary operation executed
  input  ternary_op_e             ternary_op_type_i,     // Type of operation
  input  logic                    ternary_overflow_i,    // Overflow occurred

  // Neural unit events
  input  logic                    neural_op_valid_i,     // Neural operation executed
  input  neural_op_e              neural_op_type_i,      // Type of neural op
  input  logic                    cache_hit_i,           // Cache hit
  input  logic                    cache_miss_i,          // Cache miss
  input  logic [7:0]              sparsity_ratio_i,      // Sparsity percentage

  // CSR interface
  input  logic [11:0]             csr_addr_i,            // CSR address
  input  logic                    csr_we_i,              // CSR write enable
  input  logic [31:0]             csr_wdata_i,           // CSR write data
  output logic [31:0]             csr_rdata_o,           // CSR read data
  output logic                    csr_valid_o            // CSR access valid
);

  // Counter registers
  logic [CounterWidth-1:0] cnt_ternary_ops;
  logic [CounterWidth-1:0] cnt_neural_ops;
  logic [CounterWidth-1:0] cnt_cache_hits;
  logic [CounterWidth-1:0] cnt_cache_misses;
  logic [CounterWidth-1:0] cnt_sparse_skips;
  logic [CounterWidth-1:0] cnt_overflow;
  logic [CounterWidth-1:0] cnt_ternary_cycles;
  logic [CounterWidth-1:0] cnt_neural_cycles;

  // Per-operation type counters
  logic [CounterWidth-1:0] cnt_tadd;
  logic [CounterWidth-1:0] cnt_tsub;
  logic [CounterWidth-1:0] cnt_tmul;
  logic [CounterWidth-1:0] cnt_tlogic;  // AND, OR, XOR, NOT combined

  // CSR addresses
  localparam logic [11:0] CSR_TERNARY_OPS     = 12'hB00;
  localparam logic [11:0] CSR_NEURAL_OPS      = 12'hB01;
  localparam logic [11:0] CSR_CACHE_HITS      = 12'hB02;
  localparam logic [11:0] CSR_CACHE_MISSES    = 12'hB03;
  localparam logic [11:0] CSR_SPARSE_SKIPS    = 12'hB04;
  localparam logic [11:0] CSR_OVERFLOW_COUNT  = 12'hB05;
  localparam logic [11:0] CSR_TERNARY_CYCLES  = 12'hB06;
  localparam logic [11:0] CSR_NEURAL_CYCLES   = 12'hB07;
  localparam logic [11:0] CSR_TADD_COUNT      = 12'hB08;
  localparam logic [11:0] CSR_TSUB_COUNT      = 12'hB09;
  localparam logic [11:0] CSR_TMUL_COUNT      = 12'hB0A;
  localparam logic [11:0] CSR_TLOGIC_COUNT    = 12'hB0B;

  // State tracking for cycle counting
  logic ternary_active;
  logic neural_active;

  // Main counter update logic
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      cnt_ternary_ops    <= '0;
      cnt_neural_ops     <= '0;
      cnt_cache_hits     <= '0;
      cnt_cache_misses   <= '0;
      cnt_sparse_skips   <= '0;
      cnt_overflow       <= '0;
      cnt_ternary_cycles <= '0;
      cnt_neural_cycles  <= '0;
      cnt_tadd           <= '0;
      cnt_tsub           <= '0;
      cnt_tmul           <= '0;
      cnt_tlogic         <= '0;
      ternary_active     <= 1'b0;
      neural_active      <= 1'b0;
    end else if (clear_i) begin
      cnt_ternary_ops    <= '0;
      cnt_neural_ops     <= '0;
      cnt_cache_hits     <= '0;
      cnt_cache_misses   <= '0;
      cnt_sparse_skips   <= '0;
      cnt_overflow       <= '0;
      cnt_ternary_cycles <= '0;
      cnt_neural_cycles  <= '0;
      cnt_tadd           <= '0;
      cnt_tsub           <= '0;
      cnt_tmul           <= '0;
      cnt_tlogic         <= '0;
      ternary_active     <= 1'b0;
      neural_active      <= 1'b0;
    end else if (enable_i) begin
      // Ternary operation counting
      if (ternary_op_valid_i) begin
        cnt_ternary_ops <= cnt_ternary_ops + 1;
        ternary_active  <= 1'b1;

        // Per-operation type counting
        unique case (ternary_op_type_i)
          TERNARY_ADD: cnt_tadd   <= cnt_tadd + 1;
          TERNARY_SUB: cnt_tsub   <= cnt_tsub + 1;
          TERNARY_MUL: cnt_tmul   <= cnt_tmul + 1;
          default:     cnt_tlogic <= cnt_tlogic + 1;
        endcase
      end else begin
        ternary_active <= 1'b0;
      end

      // Neural operation counting
      if (neural_op_valid_i) begin
        cnt_neural_ops <= cnt_neural_ops + 1;
        neural_active  <= 1'b1;
      end else begin
        neural_active <= 1'b0;
      end

      // Cache statistics
      if (cache_hit_i) begin
        cnt_cache_hits <= cnt_cache_hits + 1;
      end
      if (cache_miss_i) begin
        cnt_cache_misses <= cnt_cache_misses + 1;
      end

      // Sparsity tracking (count when high sparsity detected)
      if (neural_op_valid_i && sparsity_ratio_i > 8'd50) begin
        cnt_sparse_skips <= cnt_sparse_skips + 1;
      end

      // Overflow counting
      if (ternary_overflow_i) begin
        cnt_overflow <= cnt_overflow + 1;
      end

      // Cycle counting
      if (ternary_active) begin
        cnt_ternary_cycles <= cnt_ternary_cycles + 1;
      end
      if (neural_active) begin
        cnt_neural_cycles <= cnt_neural_cycles + 1;
      end

      // CSR write handling
      if (csr_we_i) begin
        unique case (csr_addr_i)
          CSR_TERNARY_OPS:    cnt_ternary_ops    <= csr_wdata_i[CounterWidth-1:0];
          CSR_NEURAL_OPS:     cnt_neural_ops     <= csr_wdata_i[CounterWidth-1:0];
          CSR_CACHE_HITS:     cnt_cache_hits     <= csr_wdata_i[CounterWidth-1:0];
          CSR_CACHE_MISSES:   cnt_cache_misses   <= csr_wdata_i[CounterWidth-1:0];
          CSR_SPARSE_SKIPS:   cnt_sparse_skips   <= csr_wdata_i[CounterWidth-1:0];
          CSR_OVERFLOW_COUNT: cnt_overflow       <= csr_wdata_i[CounterWidth-1:0];
          CSR_TERNARY_CYCLES: cnt_ternary_cycles <= csr_wdata_i[CounterWidth-1:0];
          CSR_NEURAL_CYCLES:  cnt_neural_cycles  <= csr_wdata_i[CounterWidth-1:0];
          CSR_TADD_COUNT:     cnt_tadd           <= csr_wdata_i[CounterWidth-1:0];
          CSR_TSUB_COUNT:     cnt_tsub           <= csr_wdata_i[CounterWidth-1:0];
          CSR_TMUL_COUNT:     cnt_tmul           <= csr_wdata_i[CounterWidth-1:0];
          CSR_TLOGIC_COUNT:   cnt_tlogic         <= csr_wdata_i[CounterWidth-1:0];
          default: ;
        endcase
      end
    end
  end

  // CSR read logic
  always_comb begin
    csr_rdata_o = '0;
    csr_valid_o = 1'b0;

    unique case (csr_addr_i)
      CSR_TERNARY_OPS: begin
        csr_rdata_o = {{(32-CounterWidth){1'b0}}, cnt_ternary_ops};
        csr_valid_o = 1'b1;
      end
      CSR_NEURAL_OPS: begin
        csr_rdata_o = {{(32-CounterWidth){1'b0}}, cnt_neural_ops};
        csr_valid_o = 1'b1;
      end
      CSR_CACHE_HITS: begin
        csr_rdata_o = {{(32-CounterWidth){1'b0}}, cnt_cache_hits};
        csr_valid_o = 1'b1;
      end
      CSR_CACHE_MISSES: begin
        csr_rdata_o = {{(32-CounterWidth){1'b0}}, cnt_cache_misses};
        csr_valid_o = 1'b1;
      end
      CSR_SPARSE_SKIPS: begin
        csr_rdata_o = {{(32-CounterWidth){1'b0}}, cnt_sparse_skips};
        csr_valid_o = 1'b1;
      end
      CSR_OVERFLOW_COUNT: begin
        csr_rdata_o = {{(32-CounterWidth){1'b0}}, cnt_overflow};
        csr_valid_o = 1'b1;
      end
      CSR_TERNARY_CYCLES: begin
        csr_rdata_o = {{(32-CounterWidth){1'b0}}, cnt_ternary_cycles};
        csr_valid_o = 1'b1;
      end
      CSR_NEURAL_CYCLES: begin
        csr_rdata_o = {{(32-CounterWidth){1'b0}}, cnt_neural_cycles};
        csr_valid_o = 1'b1;
      end
      CSR_TADD_COUNT: begin
        csr_rdata_o = {{(32-CounterWidth){1'b0}}, cnt_tadd};
        csr_valid_o = 1'b1;
      end
      CSR_TSUB_COUNT: begin
        csr_rdata_o = {{(32-CounterWidth){1'b0}}, cnt_tsub};
        csr_valid_o = 1'b1;
      end
      CSR_TMUL_COUNT: begin
        csr_rdata_o = {{(32-CounterWidth){1'b0}}, cnt_tmul};
        csr_valid_o = 1'b1;
      end
      CSR_TLOGIC_COUNT: begin
        csr_rdata_o = {{(32-CounterWidth){1'b0}}, cnt_tlogic};
        csr_valid_o = 1'b1;
      end
      default: begin
        csr_rdata_o = '0;
        csr_valid_o = 1'b0;
      end
    endcase
  end

  ///////////////////////////
  // Formal Verification   //
  ///////////////////////////

  // Counters should never overflow (in reasonable operation)
  `ASSERT(TernaryOpsNoOverflow, cnt_ternary_ops <= {CounterWidth{1'b1}}, clk_i, !rst_ni)
  `ASSERT(NeuralOpsNoOverflow, cnt_neural_ops <= {CounterWidth{1'b1}}, clk_i, !rst_ni)

  // Cache hits + misses should be consistent
  `ASSERT(CacheConsistency,
    (cnt_cache_hits + cnt_cache_misses) >= cnt_cache_hits, clk_i, !rst_ni)

  // CSR valid only for known addresses
  `ASSERT(CSRValidOnlyKnown,
    csr_valid_o |-> (csr_addr_i >= CSR_TERNARY_OPS && csr_addr_i <= CSR_TLOGIC_COUNT),
    clk_i, !rst_ni)

  // Reset clears all counters
  `ASSERT(ResetClearsCounters, !rst_ni |=> (cnt_ternary_ops == '0), clk_i, 1'b1)

endmodule
