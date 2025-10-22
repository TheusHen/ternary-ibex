// MHX Ternary UVM Testbench Top
// Top-level module for UVM-based ternary extension verification

`timescale 1ns/1ps

module mhx_ternary_tb_top;

  import uvm_pkg::*;
  import mhx_ternary_pkg::*;
  `include "uvm_macros.svh"

  // Clock and reset generation
  logic clk = 0;
  logic rst_n = 0;

  // Clock generation (100MHz)
  always #5 clk = ~clk;

  // Reset sequence
  initial begin
    rst_n = 0;
    repeat(10) @(posedge clk);
    rst_n = 1;
    `uvm_info("TB_TOP", "Reset released", UVM_LOW)
  end

  // Interface instantiation
  mhx_ternary_if vif(clk, rst_n);

  // DUT instantiation (connect to actual Ibex core with ternary extensions)
  // For now, this is a placeholder - connect to your actual DUT
  ibex_top_tracing #(
    .DbgTriggerEn     (1),
    .DbgHwBreakNum    (2),
    .DmHaltAddr       (32'h1A110800),
    .DmExceptionAddr  (32'h1A110808)
  ) dut (
    .clk_i                (clk),
    .rst_ni               (rst_n),

    // Instruction memory interface
    .instr_req_o          (),
    .instr_gnt_i          (1'b1),
    .instr_rvalid_i       (1'b1),
    .instr_addr_o         (),
    .instr_rdata_i        (32'h00000013), // NOP instruction
    .instr_err_i          (1'b0),

    // Data memory interface
    .data_req_o           (),
    .data_gnt_i           (1'b1),
    .data_rvalid_i        (1'b1),
    .data_we_o            (),
    .data_be_o            (),
    .data_addr_o          (),
    .data_wdata_o         (),
    .data_rdata_i         (32'h0),
    .data_err_i           (1'b0),

    // Interrupt inputs
    .irq_software_i       (1'b0),
    .irq_timer_i          (1'b0),
    .irq_external_i       (1'b0),
    .irq_fast_i           (15'b0),
    .irq_nm_i             (1'b0),

    // Debug interface
    .debug_req_i          (1'b0),
    .crash_dump_o         (),
    .double_fault_seen_o  (),

    // CPU control signals
    .fetch_enable_i       (1'b1),
    .alert_minor_o        (),
    .alert_major_internal_o(),
    .alert_major_bus_o    (),
    .core_sleep_o         ()
  );

  // Connect interface signals to DUT
  // Note: These connections need to be adapted to your actual DUT ports
  assign vif.instr_valid_i = 1'b1; // Placeholder
  assign vif.instr_rdata_i = 32'h00000013; // Placeholder
  assign vif.pc_id = 32'h0; // Placeholder

  // TODO: Connect actual ternary extension signals
  // assign vif.ternary_en_id = dut.ternary_en_id;
  // assign vif.neural_en_id = dut.neural_en_id;
  // ... etc

  // UVM testbench initialization
  initial begin
    // Set virtual interface in config_db
    uvm_config_db#(virtual mhx_ternary_if)::set(null, "*", "vif", vif);

    // Enable waveform dumping
    if ($test$plusargs("DUMP_WAVES")) begin
      $dumpfile("mhx_ternary_waves.vcd");
      $dumpvars(0, mhx_ternary_tb_top);
    end

    // Set default test timeout
    uvm_top.set_timeout(10ms);

    // Start UVM test
    run_test();
  end

  // Simulation control
  initial begin
    // Set maximum simulation time
    #100ms;
    `uvm_fatal("TB_TOP", "Simulation timeout reached")
  end

  // Monitor for simulation end conditions
  always @(posedge clk) begin
    // Add any global monitoring here
  end

  // Assertions for basic connectivity
  property clk_running;
    @(posedge clk) 1'b1;
  endproperty

  property reset_behavior;
    @(posedge clk) $rose(rst_n) |-> ##[1:10] rst_n;
  endproperty

  assert_clk_running: assert property(clk_running)
    else `uvm_error("TB_TOP", "Clock not running");

  assert_reset_behavior: assert property(reset_behavior)
    else `uvm_error("TB_TOP", "Reset behavior violation");

endmodule : mhx_ternary_tb_top
// MHX Ternary UVM Testbench Top
// Top-level module for UVM-based ternary extension verification

`timescale 1ns/1ps

module mhx_ternary_tb_top;

  import uvm_pkg::*;
  import mhx_ternary_pkg::*;
  `include "uvm_macros.svh"

  // Clock and reset generation
  logic clk = 0;
  logic rst_n = 0;

  // Clock generation (100MHz)
  always #5 clk = ~clk;

  // Reset sequence
  initial begin
    rst_n = 0;
    repeat(10) @(posedge clk);
    rst_n = 1;
    `uvm_info("TB_TOP", "Reset released", UVM_LOW)
  end

  // Interface instantiation
  mhx_ternary_if vif(clk, rst_n);

  // DUT instantiation (connect to actual Ibex core with ternary extensions)
  // For now, this is a placeholder - connect to your actual DUT
  ibex_top_tracing #(
    .DbgTriggerEn     (1),
    .DbgHwBreakNum    (2),
    .DmHaltAddr       (32'h1A110800),
    .DmExceptionAddr  (32'h1A110808)
  ) dut (
    .clk_i                (clk),
    .rst_ni               (rst_n),

    // Instruction memory interface
    .instr_req_o          (),
    .instr_gnt_i          (1'b1),
    .instr_rvalid_i       (1'b1),
    .instr_addr_o         (),
    .instr_rdata_i        (32'h00000013), // NOP instruction
    .instr_err_i          (1'b0),

    // Data memory interface
    .data_req_o           (),
    .data_gnt_i           (1'b1),
    .data_rvalid_i        (1'b1),
    .data_we_o            (),
    .data_be_o            (),
    .data_addr_o          (),
    .data_wdata_o         (),
    .data_rdata_i         (32'h0),
    .data_err_i           (1'b0),

    // Interrupt inputs
    .irq_software_i       (1'b0),
    .irq_timer_i          (1'b0),
    .irq_external_i       (1'b0),
    .irq_fast_i           (15'b0),
    .irq_nm_i             (1'b0),

    // Debug interface
    .debug_req_i          (1'b0),
    .crash_dump_o         (),
    .double_fault_seen_o  (),

    // CPU control signals
    .fetch_enable_i       (1'b1),
    .alert_minor_o        (),
    .alert_major_internal_o(),
    .alert_major_bus_o    (),
    .core_sleep_o         ()
  );

  // Connect interface signals to DUT
  // Note: These connections need to be adapted to your actual DUT ports
  assign vif.instr_valid_i = 1'b1; // Placeholder
  assign vif.instr_rdata_i = 32'h00000013; // Placeholder
  assign vif.pc_id = 32'h0; // Placeholder

  // TODO: Connect actual ternary extension signals
  // assign vif.ternary_en_id = dut.ternary_en_id;
  // assign vif.neural_en_id = dut.neural_en_id;
  // ... etc

  // UVM testbench initialization
  initial begin
    // Set virtual interface in config_db
    uvm_config_db#(virtual mhx_ternary_if)::set(null, "*", "vif", vif);

    // Enable waveform dumping
    if ($test$plusargs("DUMP_WAVES")) begin
      $dumpfile("mhx_ternary_waves.vcd");
      $dumpvars(0, mhx_ternary_tb_top);
    end

    // Set default test timeout
    uvm_top.set_timeout(10ms);

    // Start UVM test
    run_test();
  end

  // Simulation control
  initial begin
    // Set maximum simulation time
    #100ms;
    `uvm_fatal("TB_TOP", "Simulation timeout reached")
  end

  // Monitor for simulation end conditions
  always @(posedge clk) begin
    // Add any global monitoring here
  end

  // Assertions for basic connectivity
  property clk_running;
    @(posedge clk) 1'b1;
  endproperty

  property reset_behavior;
    @(posedge clk) $rose(rst_n) |-> ##[1:10] rst_n;
  endproperty

  assert_clk_running: assert property(clk_running)
    else `uvm_error("TB_TOP", "Clock not running");

  assert_reset_behavior: assert property(reset_behavior)
    else `uvm_error("TB_TOP", "Reset behavior violation");

endmodule : mhx_ternary_tb_top
