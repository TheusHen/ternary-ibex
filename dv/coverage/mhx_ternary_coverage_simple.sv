// Copyright lowRISC contributors.
// Copyright 2025 MHX Neural.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/**
 * Simplified Coverage Test for MHX Ternary Extensions
 * Compatible with Verilator - uses basic simulation without SystemVerilog covergroups
 */

`include "prim_assert.sv"

module mhx_ternary_coverage_test;

  import ibex_pkg::*;

  // Clock and reset
  logic clk;
  logic rst_ni;

  // Test signals
  logic [31:0] test_operand_a;
  logic [31:0] test_operand_b;
  logic [2:0]  test_operation;
  logic        test_enable;
  logic [31:0] alu_result;
  logic        alu_ready;

  // Neural unit signals  
  logic [31:0] neural_weights;
  logic [31:0] neural_inputs;
  logic [1:0]  neural_op;
  logic [31:0] neural_result;
  logic        neural_valid;

  // Test counter and control
  logic [31:0] test_counter;
  logic [7:0]  current_test_phase;
  
  // Clock generation
  /* verilator lint_off INFINITELOOP */
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end
  /* verilator lint_on INFINITELOOP */

  // Reset generation
  initial begin
    rst_ni = 0;
    #100 rst_ni = 1;
  end

  // Instantiate DUT components for testing
  /* verilator lint_off PINMISSING */
  ibex_ternary_alu #(
    .WIDTH(32),
    .ENABLE_VECTORIZATION(1'b1),
    .ENABLE_POWER_OPT(1'b1),
    .ENABLE_NEURAL_ACC(1'b1)
  ) dut_alu (
    .clk_i(clk),
    .rst_ni(rst_ni),
    .operand_a_i(test_operand_a),
    .operand_b_i(test_operand_b),
    .operator_i(ternary_op_e'(test_operation)),
    .enable_i(test_enable),
    .precision_mode_i(2'b00),
    .vectorize_enable_i(1'b1),
    .neural_acc_enable_i(1'b1),
    .power_save_mode_i(1'b0),
    .result_o(alu_result),
    .ready_o(alu_ready),
    .valid_o(),
    .efficiency_score_o(),
    .power_estimate_o(),
    .operation_latency_o()
  );

  ibex_neural_unit dut_neural (
    .weights_i(neural_weights),
    .inputs_i(neural_inputs),
    .bias_i(32'h55555555), // All zero bias
    .operation_i(neural_op_e'(neural_op)),
    .result_o(neural_result)
  );
  /* verilator lint_on PINMISSING */
  
  // Neural unit is combinational, so valid is always true when enabled
  assign neural_valid = test_enable;

  // Test sequence controller
  always_ff @(posedge clk or negedge rst_ni) begin
    if (!rst_ni) begin
      test_counter <= 0;
      current_test_phase <= 0;
      test_operand_a <= 0;
      test_operand_b <= 0;
      test_operation <= 0;
      test_enable <= 0;
      neural_weights <= 0;
      neural_inputs <= 0;
      neural_op <= 0;
    end else begin
      test_counter <= test_counter + 1;
      
      // Test phase progression
      if (test_counter[7:0] == 8'hFF) begin
        current_test_phase <= current_test_phase + 1;
      end
      
      // Generate test patterns based on phase
      case (current_test_phase)
        8'd0: begin // Test ternary ALU operations
          test_enable <= 1;
          test_operation <= test_counter[2:0];
          test_operand_a <= test_counter[15:8] == 8'h00 ? 32'hAAAAAAAA :  // All +1
                           test_counter[15:8] == 8'h01 ? 32'h55555555 :  // All 0  
                           test_counter[15:8] == 8'h02 ? 32'h00000000 :  // All -1
                           32'({test_counter[31:16], test_counter[15:0]});     // Mixed
          test_operand_b <= test_counter[23:16] == 8'h00 ? 32'hAAAAAAAA :
                           test_counter[23:16] == 8'h01 ? 32'h55555555 :
                           test_counter[23:16] == 8'h02 ? 32'h00000000 :
                           32'({test_counter[15:0], test_counter[31:16]});
        end
        
        8'd1: begin // Test neural operations
          test_enable <= 1;
          neural_op <= test_counter[1:0];
          neural_weights <= test_counter[15:8] == 8'h00 ? 32'hAAAAAAAA :
                          test_counter[15:8] == 8'h01 ? 32'h55555555 :
                          test_counter[15:8] == 8'h02 ? 32'h00000000 :
                          {test_counter[23:16], test_counter[7:0]};
          neural_inputs <= test_counter[23:16] == 8'h00 ? 32'hAAAAAAAA :
                         test_counter[23:16] == 8'h01 ? 32'h55555555 :
                         test_counter[23:16] == 8'h02 ? 32'h00000000 :
                         {test_counter[7:0], test_counter[31:24]};
        end
        
        8'd2: begin // Cross-product testing
          test_enable <= 1;
          test_operation <= 3'b001; // TERNARY_ADD
          neural_op <= 2'b01;       // NEURAL_MULTIPLY
          // Use counter bits to create comprehensive combinations
          test_operand_a <= {test_counter[31:24], test_counter[23:16], 
                           test_counter[15:8], test_counter[7:0]};
          test_operand_b <= {test_counter[7:0], test_counter[15:8],
                           test_counter[23:16], test_counter[31:24]};
          neural_weights <= {test_counter[15:8], test_counter[31:24],
                           test_counter[7:0], test_counter[23:16]};
          neural_inputs <= {test_counter[23:16], test_counter[7:0],
                          test_counter[31:24], test_counter[15:8]};
        end
        
        default: begin // End test
          if (test_counter > 32'd100000) begin
            $display("Coverage test completed successfully!");
            $display("Total cycles: %d", test_counter);
            $display("Test phases completed: %d", current_test_phase);
            $finish;
          end
        end
      endcase
    end
  end

  // Simple coverage tracking (replace SystemVerilog covergroups)
  logic [31:0] alu_op_count [8];
  logic [31:0] neural_op_count [4];
  logic [31:0] pattern_count [4];
  
  always_ff @(posedge clk) begin
    if (test_enable && alu_ready) begin
      alu_op_count[test_operation] <= alu_op_count[test_operation] + 1;
    end
    
    if (test_enable && neural_valid) begin
      neural_op_count[neural_op] <= neural_op_count[neural_op] + 1;
    end
    
    // Track specific patterns
    if (test_operand_a == 32'hAAAAAAAA) pattern_count[0] <= pattern_count[0] + 1;
    if (test_operand_a == 32'h55555555) pattern_count[1] <= pattern_count[1] + 1;
    if (test_operand_a == 32'h00000000) pattern_count[2] <= pattern_count[2] + 1;
    if (test_operand_a != 32'hAAAAAAAA && test_operand_a != 32'h55555555 && 
        test_operand_a != 32'h00000000) pattern_count[3] <= pattern_count[3] + 1;
  end

  // Periodic status reporting
  always_ff @(posedge clk) begin
    if (test_counter != 0 && (test_counter % 10000) == 0) begin
      $display("Test progress: cycle %d, phase %d", test_counter, current_test_phase);
      $display("ALU ops: ADD=%d, SUB=%d, MUL=%d", 
               alu_op_count[1], alu_op_count[2], alu_op_count[3]);
      $display("Neural ops: MUL=%d, ACC=%d, ACT=%d", 
               neural_op_count[1], neural_op_count[2], neural_op_count[3]);
      $display("Patterns: POS=%d, ZERO=%d, NEG=%d, MIXED=%d",
               pattern_count[0], pattern_count[1], pattern_count[2], pattern_count[3]);
    end
  end

  // Assertions for basic functionality
  `ASSERT(AluValidResult, alu_ready |-> (alu_result !== 32'hxxxxxxxx), clk, !rst_ni)
  `ASSERT(NeuralValidResult, neural_valid |-> (neural_result !== 32'hxxxxxxxx), clk, !rst_ni)

endmodule