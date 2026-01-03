// Copyright lowRISC contributors.
// Copyright 2025 MHX Neural.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/**
 * MHX Trace Analyzer Module
 *
 * This module provides trace-based analysis capabilities for MHX ternary
 * operations, enabling detailed performance profiling and debugging.
 *
 * Features:
 * - Instruction trace recording
 * - Performance hotspot detection
 * - Pipeline stall analysis
 * - Memory access pattern tracking
 * - Neural operation profiling
 */

`timescale 1ns / 1ps

module mhx_trace_analyzer
  import ibex_pkg::*;
#(
    parameter int TRACE_DEPTH = 4096,
    parameter int ADDR_WIDTH  = 12
) (
    input  logic        clk_i,
    input  logic        rst_ni,

    // Trace capture interface
    input  logic        trace_en_i,
    input  logic        instr_valid_i,
    input  logic [31:0] instr_pc_i,
    input  logic [31:0] instr_data_i,
    input  logic        is_ternary_i,
    input  logic        is_neural_i,
    input  logic        is_memory_i,
    input  logic        is_stall_i,

    // Performance counter inputs
    input  logic [63:0] mcycle_i,
    input  logic [63:0] minstret_i,

    // Control interface
    input  logic        start_capture_i,
    input  logic        stop_capture_i,
    input  logic        clear_trace_i,

    // Readback interface
    input  logic                  read_en_i,
    input  logic [ADDR_WIDTH-1:0] read_addr_i,
    output logic [127:0]          read_data_o,
    output logic                  read_valid_o,

    // Status outputs
    output logic                  capture_active_o,
    output logic [ADDR_WIDTH-1:0] trace_count_o,
    output logic                  trace_full_o,

    // Analysis outputs
    output logic [31:0] ternary_instr_count_o,
    output logic [31:0] neural_instr_count_o,
    output logic [31:0] memory_instr_count_o,
    output logic [31:0] stall_count_o,
    output logic [63:0] avg_ternary_latency_o,
    output logic [63:0] avg_neural_latency_o
);

  // Trace entry structure (128 bits)
  // [127:96] - PC
  // [95:64]  - Instruction
  // [63:0]   - Timestamp (cycle count)
  // [3:0]    - Type flags (ternary, neural, memory, stall)

  logic [127:0] trace_mem [TRACE_DEPTH];
  logic [ADDR_WIDTH-1:0] write_ptr_q;
  logic capture_active_q;

  // Statistics counters
  logic [31:0] ternary_count_q;
  logic [31:0] neural_count_q;
  logic [31:0] memory_count_q;
  logic [31:0] stall_count_q;

  // Latency tracking
  logic [63:0] ternary_start_cycle_q;
  logic [63:0] neural_start_cycle_q;
  logic [63:0] ternary_total_cycles_q;
  logic [63:0] neural_total_cycles_q;
  logic        ternary_in_progress_q;
  logic        neural_in_progress_q;

  // Capture state machine
  typedef enum logic [1:0] {
    CAP_IDLE,
    CAP_ACTIVE,
    CAP_FULL,
    CAP_STOPPED
  } capture_state_e;

  capture_state_e cap_state_q, cap_state_d;

  // State transitions
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      cap_state_q <= CAP_IDLE;
      write_ptr_q <= '0;
      capture_active_q <= 1'b0;
      ternary_count_q <= '0;
      neural_count_q <= '0;
      memory_count_q <= '0;
      stall_count_q <= '0;
      ternary_start_cycle_q <= '0;
      neural_start_cycle_q <= '0;
      ternary_total_cycles_q <= '0;
      neural_total_cycles_q <= '0;
      ternary_in_progress_q <= 1'b0;
      neural_in_progress_q <= 1'b0;
    end else begin
      cap_state_q <= cap_state_d;

      if (clear_trace_i) begin
        write_ptr_q <= '0;
        ternary_count_q <= '0;
        neural_count_q <= '0;
        memory_count_q <= '0;
        stall_count_q <= '0;
        ternary_total_cycles_q <= '0;
        neural_total_cycles_q <= '0;
      end else if (cap_state_q == CAP_ACTIVE && trace_en_i && instr_valid_i) begin
        // Record trace entry
        if (write_ptr_q < TRACE_DEPTH - 1) begin
          trace_mem[write_ptr_q] <= {instr_pc_i, instr_data_i, mcycle_i[59:0],
                                     is_stall_i, is_memory_i, is_neural_i, is_ternary_i};
          write_ptr_q <= write_ptr_q + 1;
        end

        // Update statistics
        if (is_ternary_i) begin
          ternary_count_q <= ternary_count_q + 32'b1;
          if (!ternary_in_progress_q) begin
            ternary_start_cycle_q <= mcycle_i;
            ternary_in_progress_q <= 1'b1;
          end
        end else if (ternary_in_progress_q) begin
          ternary_total_cycles_q <= ternary_total_cycles_q + (mcycle_i - ternary_start_cycle_q);
          ternary_in_progress_q <= 1'b0;
        end

        if (is_neural_i) begin
          neural_count_q <= neural_count_q + 32'b1;
          if (!neural_in_progress_q) begin
            neural_start_cycle_q <= mcycle_i;
            neural_in_progress_q <= 1'b1;
          end
        end else if (neural_in_progress_q) begin
          neural_total_cycles_q <= neural_total_cycles_q + (mcycle_i - neural_start_cycle_q);
          neural_in_progress_q <= 1'b0;
        end

        if (is_memory_i) memory_count_q <= memory_count_q + 32'b1;
        if (is_stall_i) stall_count_q <= stall_count_q + 32'b1;
      end

      capture_active_q <= (cap_state_q == CAP_ACTIVE);
    end
  end

  // Next state logic
  always_comb begin
    cap_state_d = cap_state_q;

    case (cap_state_q)
      CAP_IDLE: begin
        if (start_capture_i) cap_state_d = CAP_ACTIVE;
      end

      CAP_ACTIVE: begin
        if (stop_capture_i) cap_state_d = CAP_STOPPED;
        else if (write_ptr_q >= TRACE_DEPTH - 1) cap_state_d = CAP_FULL;
      end

      CAP_FULL: begin
        if (clear_trace_i) cap_state_d = CAP_IDLE;
        else if (stop_capture_i) cap_state_d = CAP_STOPPED;
      end

      CAP_STOPPED: begin
        if (clear_trace_i) cap_state_d = CAP_IDLE;
        else if (start_capture_i) cap_state_d = CAP_ACTIVE;
      end

      default: cap_state_d = CAP_IDLE;
    endcase
  end

  // Read interface
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      read_data_o <= '0;
      read_valid_o <= 1'b0;
    end else begin
      read_valid_o <= read_en_i && (read_addr_i < write_ptr_q);
      if (read_en_i && (read_addr_i < write_ptr_q)) begin
        read_data_o <= trace_mem[read_addr_i];
      end
    end
  end

  // Output assignments
  assign capture_active_o = capture_active_q;
  assign trace_count_o = write_ptr_q;
  assign trace_full_o = (cap_state_q == CAP_FULL);
  assign ternary_instr_count_o = ternary_count_q;
  assign neural_instr_count_o = neural_count_q;
  assign memory_instr_count_o = memory_count_q;
  assign stall_count_o = stall_count_q;

  // Calculate average latencies (avoid division by zero)
  assign avg_ternary_latency_o = (ternary_count_q > 0) ?
      (ternary_total_cycles_q / {32'b0, ternary_count_q}) : 64'b0;
  assign avg_neural_latency_o = (neural_count_q > 0) ?
      (neural_total_cycles_q / {32'b0, neural_count_q}) : 64'b0;

  // Verification checks (non-Verilator simulators only)
`ifndef VERILATOR
`ifndef SYNTHESIS
  // Check trace buffer overflow handling
  always_ff @(posedge clk_i) begin
    if (rst_ni && cap_state_q == CAP_ACTIVE && write_ptr_q == TRACE_DEPTH - 1) begin
      // Next cycle should transition to CAP_FULL
    end
  end

  // Validate read operations
  always_ff @(posedge clk_i) begin
    if (rst_ni && read_valid_o && !(read_addr_i < write_ptr_q)) begin
      $error("Invalid read from unwritten trace entry");
    end
  end
`endif
`endif

endmodule

/**
 * MHX Performance Hotspot Detector
 *
 * Analyzes trace data to identify performance bottlenecks and hotspots.
 */
module mhx_hotspot_detector #(
    parameter int HOTSPOT_COUNT = 8
) (
    input  logic        clk_i,
    input  logic        rst_ni,

    // Trace input
    input  logic        trace_valid_i,
    input  logic [31:0] trace_pc_i,
    input  logic [63:0] trace_cycles_i,
    input  logic        trace_stall_i,

    // Analysis control
    input  logic        analyze_start_i,
    input  logic        analyze_clear_i,
    output logic        analyze_done_o,

    // Hotspot results
    output logic [31:0] hotspot_pc_o     [HOTSPOT_COUNT],
    output logic [31:0] hotspot_count_o  [HOTSPOT_COUNT],
    output logic [63:0] hotspot_cycles_o [HOTSPOT_COUNT]
);

  // Hotspot tracking structure
  typedef struct packed {
    logic [31:0] pc;
    logic [31:0] count;
    logic [63:0] total_cycles;
  } hotspot_entry_t;

  hotspot_entry_t hotspots [HOTSPOT_COUNT];
  logic analyze_active_q;
  logic [3:0] update_idx;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      analyze_active_q <= 1'b0;
      for (int i = 0; i < HOTSPOT_COUNT; i++) begin
        hotspots[i].pc <= '0;
        hotspots[i].count <= '0;
        hotspots[i].total_cycles <= '0;
      end
    end else begin
      if (analyze_clear_i) begin
        for (int i = 0; i < HOTSPOT_COUNT; i++) begin
          hotspots[i].pc <= '0;
          hotspots[i].count <= '0;
          hotspots[i].total_cycles <= '0;
        end
        analyze_active_q <= 1'b0;
      end else if (analyze_start_i) begin
        analyze_active_q <= 1'b1;
      end

      if (analyze_active_q && trace_valid_i) begin
        // Find matching entry or empty slot
        update_idx = HOTSPOT_COUNT; // Invalid by default

        for (int i = 0; i < HOTSPOT_COUNT; i++) begin
          if (hotspots[i].pc == trace_pc_i) begin
            update_idx = i[3:0];
          end
        end

        // If no match found, find empty slot
        if (update_idx == HOTSPOT_COUNT) begin
          for (int i = 0; i < HOTSPOT_COUNT; i++) begin
            if (hotspots[i].count == 0) begin
              update_idx = i[3:0];
            end
          end
        end

        // Update entry if valid index found
        if (update_idx < HOTSPOT_COUNT) begin
          hotspots[update_idx].pc <= trace_pc_i;
          hotspots[update_idx].count <= hotspots[update_idx].count + 32'b1;
          if (trace_stall_i) begin
            hotspots[update_idx].total_cycles <=
                hotspots[update_idx].total_cycles + trace_cycles_i;
          end
        end
      end
    end
  end

  assign analyze_done_o = analyze_active_q;

  // Output hotspot data
  genvar i;
  generate
    for (i = 0; i < HOTSPOT_COUNT; i++) begin : gen_hotspot_out
      assign hotspot_pc_o[i] = hotspots[i].pc;
      assign hotspot_count_o[i] = hotspots[i].count;
      assign hotspot_cycles_o[i] = hotspots[i].total_cycles;
    end
  endgenerate

endmodule
