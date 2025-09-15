// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/**
 * Testbench for MHX Ternary Extensions
 *
 * Tests basic functionality of:
 * - Ternary register file
 * - Ternary ALU operations
 * - Neural processing unit
 */

`include "prim_assert.sv"

module mhx_ternary_test;

  import ibex_pkg::*;

  // Clock and reset
  logic clk, rst_n;

  // Test signals
  logic [31:0] test_result;
  logic        test_ready;
  logic        test_passed;
  integer      test_count;

  // Clock generation (100MHz)
  always #5 clk = ~clk;

  // DUT signals for ternary register file
  logic [3:0]  trf_raddr_a, trf_raddr_b, trf_waddr;
  logic [31:0] trf_rdata_a, trf_rdata_b, trf_wdata;
  logic        trf_we;

  // DUT signals for ternary ALU
  ternary_op_e talu_op;
  logic [31:0] talu_result;
  logic        talu_ready;

  // DUT signals for neural unit
  neural_op_e  neural_op;
  logic [31:0] neural_weights, neural_inputs, neural_bias;
  logic [31:0] neural_result;
  logic        neural_valid;

  ////////////////////////////////////////////////
  // Instantiate Ternary Units Under Test      //
  ////////////////////////////////////////////////

  ibex_ternary_regfile dut_regfile (
    .clk_i     (clk),
    .rst_ni    (rst_n),
    .raddr_a_i (trf_raddr_a),
    .raddr_b_i (trf_raddr_b),
    .rdata_a_o (trf_rdata_a),
    .rdata_b_o (trf_rdata_b),
    .waddr_i   (trf_waddr),
    .wdata_i   (trf_wdata),
    .we_i      (trf_we)
  );

  ibex_ternary_alu dut_alu (
    .clk_i       (clk),
    .rst_ni      (rst_n),
    .operand_a_i (trf_rdata_a),
    .operand_b_i (trf_rdata_b),
    .operator_i  (talu_op),
    .result_o    (talu_result),
    .ready_o     (talu_ready)
  );

  ibex_neural_unit dut_neural (
    .weights_i   (neural_weights),
    .inputs_i    (neural_inputs),
    .bias_i      (neural_bias),
    .operation_i (neural_op),
    .result_o    (neural_result),
    .valid_o     (neural_valid)
  );

  ////////////////////////////////////////////////
  // Test Tasks                                 //
  ////////////////////////////////////////////////

  task automatic reset_dut();
    rst_n = 0;
    #20;
    rst_n = 1;
    #10;
  endtask

  task automatic write_ternary_reg(input [3:0] addr, input [31:0] data);
    @(posedge clk);
    trf_waddr = addr;
    trf_wdata = data;
    trf_we = 1'b1;
    @(posedge clk);
    trf_we = 1'b0;
  endtask

  task automatic read_ternary_reg(input [3:0] addr_a, input [3:0] addr_b);
    @(posedge clk);
    trf_raddr_a = addr_a;
    trf_raddr_b = addr_b;
    @(posedge clk);
    // Data available immediately (asynchronous read)
  endtask

  task automatic test_ternary_add(input [31:0] a, input [31:0] b, input [31:0] expected);
    $display("Testing ternary ADD: %h + %h = %h (expected %h)", a, b, talu_result, expected);
    
    // Write operands to registers
    write_ternary_reg(4'd0, a);
    write_ternary_reg(4'd1, b);
    
    // Read operands
    read_ternary_reg(4'd0, 4'd1);
    
    // Perform addition
    talu_op = TERNARY_ADD;
    @(posedge clk);
    
    // Check result
    if (talu_ready && (talu_result == expected)) begin
      $display("✓ PASS: Ternary ADD test");
      test_passed = 1'b1;
    end else begin
      $display("✗ FAIL: Ternary ADD test - got %h, expected %h", talu_result, expected);
      test_passed = 1'b0;
    end
    
    test_count++;
  endtask

  task automatic test_ternary_mul(input [31:0] a, input [31:0] b, input [31:0] expected);
    $display("Testing ternary MUL: %h * %h = %h (expected %h)", a, b, talu_result, expected);
    
    // Write operands to registers
    write_ternary_reg(4'd0, a);
    write_ternary_reg(4'd1, b);
    
    // Read operands
    read_ternary_reg(4'd0, 4'd1);
    
    // Perform multiplication
    talu_op = TERNARY_MUL;
    @(posedge clk);
    
    // Check result
    if (talu_ready && (talu_result == expected)) begin
      $display("✓ PASS: Ternary MUL test");
      test_passed = 1'b1;
    end else begin
      $display("✗ FAIL: Ternary MUL test - got %h, expected %h", talu_result, expected);
      test_passed = 1'b0;
    end
    
    test_count++;
  endtask

  task automatic test_neural_multiply();
    $display("Testing neural MULTIPLY operation");
    
    // Set up weights: all +1 (16 trits = 10101010... = 0xAAAAAAAA)
    neural_weights = 32'hAAAAAAAA;
    
    // Set up inputs: all +1  
    neural_inputs = 32'hAAAAAAAA;
    
    // Set bias to 0
    neural_bias = 32'h55555555;  // All zeros in ternary
    
    // Perform neural multiply operation
    neural_op = NEURAL_MULTIPLY;
    @(posedge clk);
    
    // Check result (16 * (+1) * (+1) + 0 = 16)
    if (neural_valid && (neural_result[7:0] == 8'd16)) begin
      $display("✓ PASS: Neural MULTIPLY test - result = %d", neural_result[7:0]);
      test_passed = 1'b1;
    end else begin
      $display("✗ FAIL: Neural MULTIPLY test - got %d, expected 16", neural_result[7:0]);
      test_passed = 1'b0;
    end
    
    test_count++;
  endtask

  task automatic test_neural_activate();
    $display("Testing neural ACTIVATE operation");
    
    // Set up inputs that will result in a large positive accumulation
    neural_weights = 32'hAAAAAAAA;  // All +1
    neural_inputs = 32'hAAAAAAAA;   // All +1
    neural_bias = 32'h55555555;     // Zero bias
    
    // Perform neural activation
    neural_op = NEURAL_ACTIVATE;
    @(posedge clk);
    
    // Check result (should be +1 since accumulation > 1)
    if (neural_valid && (neural_result[1:0] == TRIT_POS)) begin
      $display("✓ PASS: Neural ACTIVATE test - result = +1");
      test_passed = 1'b1;
    end else begin
      $display("✗ FAIL: Neural ACTIVATE test - got %b, expected %b", neural_result[1:0], TRIT_POS);
      test_passed = 1'b0;
    end
    
    test_count++;
  endtask

  ////////////////////////////////////////////////
  // Main Test Sequence                         //
  ////////////////////////////////////////////////

  initial begin
    $display("=================================================");
    $display("MHX Ternary Extension Test");
    $display("=================================================");
    
    // Initialize
    clk = 0;
    test_count = 0;
    test_passed = 1'b0;
    
    // Initialize control signals
    trf_we = 1'b0;
    trf_waddr = 4'b0;
    trf_wdata = 32'h0;
    trf_raddr_a = 4'b0;
    trf_raddr_b = 4'b0;
    talu_op = TERNARY_ADD;
    neural_op = NEURAL_MULTIPLY;
    neural_weights = 32'h0;
    neural_inputs = 32'h0;
    neural_bias = 32'h0;
    
    // Reset
    reset_dut();
    
    $display("\n--- Testing Ternary Register File ---");
    
    // Test register write/read
    $display("Testing register write/read...");
    write_ternary_reg(4'd5, 32'hDEADBEEF);
    read_ternary_reg(4'd5, 4'd0);
    
    if (trf_rdata_a == 32'hDEADBEEF) begin
      $display("✓ PASS: Register file write/read test");
    end else begin
      $display("✗ FAIL: Register file write/read test");
    end
    test_count++;
    
    $display("\n--- Testing Ternary ALU ---");
    
    // Test ternary arithmetic operations
    // Note: Using simplified test values for demonstration
    
    // Test ADD: 0 + 1 = 1 (in ternary encoding)
    test_ternary_add(32'h55555555, 32'hAAAAAAAA, 32'hAAAAAAAA);
    
    // Test MUL: 1 * 1 = 1 (in ternary encoding)  
    test_ternary_mul(32'hAAAAAAAA, 32'hAAAAAAAA, 32'hAAAAAAAA);
    
    $display("\n--- Testing Neural Unit ---");
    
    // Test neural operations
    test_neural_multiply();
    test_neural_activate();
    
    $display("\n=================================================");
    $display("Test Summary: %d tests completed", test_count);
    if (test_count > 0) begin
      $display("MHX Ternary Extension tests completed!");
    end
    $display("=================================================");
    
    $finish;
  end

  // Timeout
  initial begin
    #50000;
    $display("ERROR: Test timeout!");
    $finish;
  end

endmodule