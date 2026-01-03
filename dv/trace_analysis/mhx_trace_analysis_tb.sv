// Copyright lowRISC contributors.
// Copyright 2025 MHX™ Neural.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/**
 * MHX™ Trace-Based Analysis Testbench
 *
 * Top-level testbench integrating cycle-accurate simulation and trace analysis.
 */

`timescale 1ns / 1ps

module mhx_trace_analysis_tb;

  // Clock and reset
  logic clk;
  logic rst_n;

  // Clock generation (100 MHz)
  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  // Reset generation
  initial begin
    rst_n = 1'b0;
    #100 rst_n = 1'b1;
  end

  // Test control signals
  logic test_start;
  logic test_done;
  logic test_pass;

  // Performance metrics
  logic [63:0] total_cycles;
  logic [63:0] ternary_cycles;
  logic [63:0] neural_cycles;
  logic [63:0] stall_cycles;

  // Trace signals
  logic trace_valid;
  logic [31:0] trace_pc;
  logic [31:0] trace_instr;
  logic [63:0] trace_cycle;
  logic [2:0] trace_type;

  // Trace analyzer signals
  logic trace_en;
  logic start_capture;
  logic stop_capture;
  logic clear_trace;
  logic capture_active;
  logic [11:0] trace_count;
  logic trace_full;

  // Analysis outputs
  logic [31:0] ternary_instr_count;
  logic [31:0] neural_instr_count;
  logic [31:0] memory_instr_count;
  logic [31:0] analyzer_stall_count;
  logic [63:0] avg_ternary_latency;
  logic [63:0] avg_neural_latency;

  // Hotspot detector signals
  logic analyze_start;
  logic analyze_clear;
  logic analyze_done;
  logic [31:0] hotspot_pc [8];
  logic [31:0] hotspot_count [8];
  logic [63:0] hotspot_cycles [8];

  // Cycle counter for trace analyzer
  logic [63:0] mcycle;
  logic [63:0] minstret;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      mcycle <= 64'b0;
      minstret <= 64'b0;
    end else begin
      mcycle <= mcycle + 64'b1;
      if (trace_valid) minstret <= minstret + 64'b1;
    end
  end

  // Cycle-accurate simulator instance
  mhx_cycle_accurate_sim u_cycle_sim (
      .clk_i          (clk),
      .rst_ni         (rst_n),
      .test_start_i   (test_start),
      .test_done_o    (test_done),
      .test_pass_o    (test_pass),
      .total_cycles_o (total_cycles),
      .ternary_cycles_o(ternary_cycles),
      .neural_cycles_o(neural_cycles),
      .stall_cycles_o (stall_cycles),
      .trace_valid_o  (trace_valid),
      .trace_pc_o     (trace_pc),
      .trace_instr_o  (trace_instr),
      .trace_cycle_o  (trace_cycle),
      .trace_type_o   (trace_type)
  );

  // Trace analyzer instance
  mhx_trace_analyzer #(
      .TRACE_DEPTH(4096),
      .ADDR_WIDTH(12)
  ) u_trace_analyzer (
      .clk_i               (clk),
      .rst_ni              (rst_n),
      .trace_en_i          (trace_en),
      .instr_valid_i       (trace_valid),
      .instr_pc_i          (trace_pc),
      .instr_data_i        (trace_instr),
      .is_ternary_i        (trace_type == 3'b001),
      .is_neural_i         (trace_type == 3'b010),
      .is_memory_i         (trace_type == 3'b011),
      .is_stall_i          (trace_type == 3'b100),
      .mcycle_i            (mcycle),
      .minstret_i          (minstret),
      .start_capture_i     (start_capture),
      .stop_capture_i      (stop_capture),
      .clear_trace_i       (clear_trace),
      .read_en_i           (1'b0),
      .read_addr_i         (12'b0),
      .read_data_o         (),
      .read_valid_o        (),
      .capture_active_o    (capture_active),
      .trace_count_o       (trace_count),
      .trace_full_o        (trace_full),
      .ternary_instr_count_o(ternary_instr_count),
      .neural_instr_count_o(neural_instr_count),
      .memory_instr_count_o(memory_instr_count),
      .stall_count_o       (analyzer_stall_count),
      .avg_ternary_latency_o(avg_ternary_latency),
      .avg_neural_latency_o(avg_neural_latency)
  );

  // Hotspot detector instance
  mhx_hotspot_detector #(
      .HOTSPOT_COUNT(8)
  ) u_hotspot_detector (
      .clk_i           (clk),
      .rst_ni          (rst_n),
      .trace_valid_i   (trace_valid),
      .trace_pc_i      (trace_pc),
      .trace_cycles_i  (trace_cycle),
      .trace_stall_i   (trace_type == 3'b100),
      .analyze_start_i (analyze_start),
      .analyze_clear_i (analyze_clear),
      .analyze_done_o  (analyze_done),
      .hotspot_pc_o    (hotspot_pc),
      .hotspot_count_o (hotspot_count),
      .hotspot_cycles_o(hotspot_cycles)
  );

  // Test sequence
  initial begin
    test_start = 1'b0;
    trace_en = 1'b0;
    start_capture = 1'b0;
    stop_capture = 1'b0;
    clear_trace = 1'b0;
    analyze_start = 1'b0;
    analyze_clear = 1'b0;

    // Wait for reset
    @(posedge rst_n);
    repeat(10) @(posedge clk);

    $display("==============================================");
    $display("MHX™ Trace-Based Analysis Test");
    $display("==============================================");

    // Clear and start trace capture
    clear_trace = 1'b1;
    analyze_clear = 1'b1;
    @(posedge clk);
    clear_trace = 1'b0;
    analyze_clear = 1'b0;

    // Start capture and analysis
    trace_en = 1'b1;
    start_capture = 1'b1;
    analyze_start = 1'b1;
    @(posedge clk);
    start_capture = 1'b0;
    analyze_start = 1'b0;

    // Start the test
    $display("Starting cycle-accurate simulation...");
    test_start = 1'b1;
    @(posedge clk);
    test_start = 1'b0;

    // Wait for test completion
    wait(test_done);

    // Stop capture
    stop_capture = 1'b1;
    @(posedge clk);
    stop_capture = 1'b0;

    repeat(10) @(posedge clk);

    // Print results
    $display("");
    $display("==============================================");
    $display("Test Results");
    $display("==============================================");
    $display("Test Status:          %s", test_pass ? "PASSED" : "FAILED");
    $display("");
    $display("Cycle Metrics:");
    $display("  Total Cycles:       %0d", total_cycles);
    $display("  Ternary Cycles:     %0d", ternary_cycles);
    $display("  Neural Cycles:      %0d", neural_cycles);
    $display("  Stall Cycles:       %0d", stall_cycles);
    $display("");
    $display("Trace Analysis:");
    $display("  Trace Entries:      %0d", trace_count);
    $display("  Ternary Instrs:     %0d", ternary_instr_count);
    $display("  Neural Instrs:      %0d", neural_instr_count);
    $display("  Memory Instrs:      %0d", memory_instr_count);
    $display("  Stall Events:       %0d", analyzer_stall_count);
    $display("");
    $display("Latency Analysis:");
    $display("  Avg Ternary Latency: %0d cycles", avg_ternary_latency);
    $display("  Avg Neural Latency:  %0d cycles", avg_neural_latency);
    $display("");
    $display("Top Hotspots:");
    for (int i = 0; i < 8; i++) begin
      if (hotspot_count[i] > 0) begin
        $display("  PC=0x%08x Count=%0d Cycles=%0d",
                 hotspot_pc[i], hotspot_count[i], hotspot_cycles[i]);
      end
    end
    $display("==============================================");

    // Write results to file
    write_results_json();

    repeat(10) @(posedge clk);
    $finish;
  end

  // Write results to JSON file
  task write_results_json();
    integer fd;
    fd = $fopen("trace_analysis_results.json", "w");
    $fwrite(fd, "{\n");
    $fwrite(fd, "  \"test_status\": \"%s\",\n", test_pass ? "PASSED" : "FAILED");
    $fwrite(fd, "  \"total_cycles\": %0d,\n", total_cycles);
    $fwrite(fd, "  \"ternary_cycles\": %0d,\n", ternary_cycles);
    $fwrite(fd, "  \"neural_cycles\": %0d,\n", neural_cycles);
    $fwrite(fd, "  \"stall_cycles\": %0d,\n", stall_cycles);
    $fwrite(fd, "  \"trace_entries\": %0d,\n", trace_count);
    $fwrite(fd, "  \"ternary_instr_count\": %0d,\n", ternary_instr_count);
    $fwrite(fd, "  \"neural_instr_count\": %0d,\n", neural_instr_count);
    $fwrite(fd, "  \"memory_instr_count\": %0d,\n", memory_instr_count);
    $fwrite(fd, "  \"stall_count\": %0d,\n", analyzer_stall_count);
    $fwrite(fd, "  \"avg_ternary_latency\": %0d,\n", avg_ternary_latency);
    $fwrite(fd, "  \"avg_neural_latency\": %0d,\n", avg_neural_latency);
    $fwrite(fd, "  \"hotspots\": [\n");
    for (int i = 0; i < 8; i++) begin
      if (hotspot_count[i] > 0) begin
        $fwrite(fd, "    {\"pc\": \"0x%08x\", \"count\": %0d, \"cycles\": %0d}%s\n",
                hotspot_pc[i], hotspot_count[i], hotspot_cycles[i],
                (i < 7 && hotspot_count[i+1] > 0) ? "," : "");
      end
    end
    $fwrite(fd, "  ]\n");
    $fwrite(fd, "}\n");
    $fclose(fd);
    $display("Results written to trace_analysis_results.json");
  endtask

  // Timeout
  initial begin
    #10000000;
    $display("ERROR: Test timeout!");
    $finish;
  end

endmodule
