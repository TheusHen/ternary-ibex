// Copyright lowRISC contributors.
// Copyright 2025 MHX™ Neural.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/**
 * Directed Tests for Coverage Closure
 *
 * This file contains directed test sequences designed to close coverage holes
 * and achieve 90%+ functional coverage. Tests target specific scenarios that
 * are unlikely to be hit by random testing alone.
 *
 * Coverage Goals:
 * - Ternary operations: 90%+
 * - Neural operations: 90%+
 * - Ternary-Neural interactions: 90%+
 * - Corner cases: 95%+
 * - Error scenarios: 90%+
 */

// Directed test for all ternary operation combinations
class mhx_ternary_all_ops_test extends mhx_ternary_base_test;
  `uvm_component_utils(mhx_ternary_all_ops_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    mhx_ternary_sequence seq;
    
    phase.raise_objection(this);
    `uvm_info("TEST", "Running all ternary operations directed test", UVM_LOW)

    // Test each operation with all register combinations
    for (int op = 0; op < 7; op++) begin
      for (int rs1 = 0; rs1 < 32; rs1++) begin
        for (int rs2 = 0; rs2 < 32; rs2++) begin
          for (int rd = 0; rd < 32; rd++) begin
            seq = mhx_ternary_sequence::type_id::create("seq");
            seq.ternary_operation = ternary_op_e'(op);
            seq.ternary_rs1 = rs1;
            seq.ternary_rs2 = rs2;
            seq.ternary_rd = rd;
            seq.start(env.agent.sequencer);
          end
        end
      end
    end

    phase.drop_objection(this);
  endtask
endclass

// Directed test for corner case data patterns
class mhx_ternary_corner_cases_test extends mhx_ternary_base_test;
  `uvm_component_utils(mhx_ternary_corner_cases_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    mhx_ternary_sequence seq;
    logic [31:0] corner_patterns[] = '{
      32'h00000000,  // All -1
      32'h55555555,  // All 0
      32'hAAAAAAAA,  // All +1
      32'h50A050A0,  // Alternating 1
      32'hA050A050,  // Alternating 2
      32'h0A50A50A,  // Alternating 3
      32'h50505050,  // Pattern 1
      32'hA0A0A0A0,  // Pattern 2
      32'h00005555,  // Half -1, half 0
      32'h5555AAAA,  // Half 0, half +1
      32'hFFFFFFFF,  // All invalid (for error testing)
      32'h55AA55AA   // Mixed pattern
    };

    phase.raise_objection(this);
    `uvm_info("TEST", "Running corner cases directed test", UVM_LOW)

    // Test all operations with corner case patterns
    foreach (corner_patterns[i]) begin
      foreach (corner_patterns[j]) begin
        for (int op = 0; op < 7; op++) begin
          seq = mhx_ternary_sequence::type_id::create("seq");
          seq.ternary_operation = ternary_op_e'(op);
          seq.operand_a = corner_patterns[i];
          seq.operand_b = corner_patterns[j];
          seq.start(env.agent.sequencer);
        end
      end
    end

    phase.drop_objection(this);
  endtask
endclass

// Directed test for overflow scenarios
class mhx_ternary_overflow_test extends mhx_ternary_base_test;
  `uvm_component_utils(mhx_ternary_overflow_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    mhx_ternary_sequence seq;

    phase.raise_objection(this);
    `uvm_info("TEST", "Running overflow scenarios directed test", UVM_LOW)

    // Test ADD with patterns that cause overflow
    for (int trit_pos = 0; trit_pos < 16; trit_pos++) begin
      // (-1) + (-1) = overflow at each trit position
      seq = mhx_ternary_sequence::type_id::create("seq");
      seq.ternary_operation = TERNARY_ADD;
      seq.operand_a = 32'h00000000;  // All -1
      seq.operand_b = 32'h00000000;  // All -1
      seq.start(env.agent.sequencer);

      // (+1) + (+1) = overflow at each trit position
      seq = mhx_ternary_sequence::type_id::create("seq");
      seq.ternary_operation = TERNARY_ADD;
      seq.operand_a = 32'hAAAAAAAA;  // All +1
      seq.operand_b = 32'hAAAAAAAA;  // All +1
      seq.start(env.agent.sequencer);
    end

    // Test SUB with patterns that cause overflow
    for (int trit_pos = 0; trit_pos < 16; trit_pos++) begin
      // (-1) - (+1) = overflow
      seq = mhx_ternary_sequence::type_id::create("seq");
      seq.ternary_operation = TERNARY_SUB;
      seq.operand_a = 32'h00000000;  // All -1
      seq.operand_b = 32'hAAAAAAAA;  // All +1
      seq.start(env.agent.sequencer);

      // (+1) - (-1) = overflow
      seq = mhx_ternary_sequence::type_id::create("seq");
      seq.ternary_operation = TERNARY_SUB;
      seq.operand_a = 32'hAAAAAAAA;  // All +1
      seq.operand_b = 32'h00000000;  // All -1
      seq.start(env.agent.sequencer);
    end

    phase.drop_objection(this);
  endtask
endclass

// Directed test for back-to-back operations
class mhx_ternary_back_to_back_test extends mhx_ternary_base_test;
  `uvm_component_utils(mhx_ternary_back_to_back_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    mhx_ternary_sequence seq1, seq2;

    phase.raise_objection(this);
    `uvm_info("TEST", "Running back-to-back operations test", UVM_LOW)

    // Test all operation pairs back-to-back
    for (int op1 = 0; op1 < 7; op1++) begin
      for (int op2 = 0; op2 < 7; op2++) begin
        seq1 = mhx_ternary_sequence::type_id::create("seq1");
        seq1.ternary_operation = ternary_op_e'(op1);
        seq1.ternary_rd = 5;  // Write to T5
        
        seq2 = mhx_ternary_sequence::type_id::create("seq2");
        seq2.ternary_operation = ternary_op_e'(op2);
        seq2.ternary_rs1 = 5;  // Read from T5 (RAW hazard)
        
        // Execute back-to-back
        seq1.start(env.agent.sequencer);
        seq2.start(env.agent.sequencer);
      end
    end

    phase.drop_objection(this);
  endtask
endclass

// Directed test for ternary-neural interactions
class mhx_ternary_neural_interaction_test extends mhx_ternary_base_test;
  `uvm_component_utils(mhx_ternary_neural_interaction_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    mhx_ternary_sequence ternary_seq;
    mhx_neural_sequence neural_seq;

    phase.raise_objection(this);
    `uvm_info("TEST", "Running ternary-neural interaction test", UVM_LOW)

    // Test all ternary → neural transitions
    for (int t_op = 0; t_op < 7; t_op++) begin
      for (int n_op = 0; n_op < 4; n_op++) begin
        ternary_seq = mhx_ternary_sequence::type_id::create("ternary_seq");
        ternary_seq.ternary_operation = ternary_op_e'(t_op);
        ternary_seq.ternary_rd = 10;
        ternary_seq.start(env.agent.sequencer);

        neural_seq = mhx_neural_sequence::type_id::create("neural_seq");
        neural_seq.neural_operation = neural_op_e'(n_op);
        neural_seq.neural_rs1 = 10;  // Use result from ternary
        neural_seq.start(env.agent.sequencer);
      end
    end

    // Test all neural → ternary transitions
    for (int n_op = 0; n_op < 4; n_op++) begin
      for (int t_op = 0; t_op < 7; t_op++) begin
        neural_seq = mhx_neural_sequence::type_id::create("neural_seq");
        neural_seq.neural_operation = neural_op_e'(n_op);
        neural_seq.neural_rd = 15;
        neural_seq.start(env.agent.sequencer);

        ternary_seq = mhx_ternary_sequence::type_id::create("ternary_seq");
        ternary_seq.ternary_operation = ternary_op_e'(t_op);
        ternary_seq.ternary_rs1 = 15;  // Use result from neural
        ternary_seq.start(env.agent.sequencer);
      end
    end

    phase.drop_objection(this);
  endtask
endclass

// Directed test for register hazards (RAW, WAW)
class mhx_ternary_hazards_test extends mhx_ternary_base_test;
  `uvm_component_utils(mhx_ternary_hazards_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    mhx_ternary_sequence seq1, seq2, seq3;

    phase.raise_objection(this);
    `uvm_info("TEST", "Running register hazards test", UVM_LOW)

    // Test RAW (Read-After-Write) hazards
    for (int reg_idx = 1; reg_idx < 32; reg_idx++) begin
      seq1 = mhx_ternary_sequence::type_id::create("seq1");
      seq1.ternary_operation = TERNARY_ADD;
      seq1.ternary_rd = reg_idx;  // Write
      seq1.start(env.agent.sequencer);

      seq2 = mhx_ternary_sequence::type_id::create("seq2");
      seq2.ternary_operation = TERNARY_MUL;
      seq2.ternary_rs1 = reg_idx;  // Read (RAW)
      seq2.start(env.agent.sequencer);
    end

    // Test WAW (Write-After-Write) hazards
    for (int reg_idx = 1; reg_idx < 32; reg_idx++) begin
      seq1 = mhx_ternary_sequence::type_id::create("seq1");
      seq1.ternary_operation = TERNARY_ADD;
      seq1.ternary_rd = reg_idx;  // Write
      seq1.start(env.agent.sequencer);

      seq2 = mhx_ternary_sequence::type_id::create("seq2");
      seq2.ternary_operation = TERNARY_SUB;
      seq2.ternary_rd = reg_idx;  // Write (WAW)
      seq2.start(env.agent.sequencer);
    end

    // Test WAR (Write-After-Read) hazards
    for (int reg_idx = 1; reg_idx < 32; reg_idx++) begin
      seq1 = mhx_ternary_sequence::type_id::create("seq1");
      seq1.ternary_operation = TERNARY_AND;
      seq1.ternary_rs1 = reg_idx;  // Read
      seq1.start(env.agent.sequencer);

      seq2 = mhx_ternary_sequence::type_id::create("seq2");
      seq2.ternary_operation = TERNARY_OR;
      seq2.ternary_rd = reg_idx;  // Write (WAR)
      seq2.start(env.agent.sequencer);
    end

    phase.drop_objection(this);
  endtask
endclass

// Directed test for neural weight patterns
class mhx_neural_weight_patterns_test extends mhx_ternary_base_test;
  `uvm_component_utils(mhx_neural_weight_patterns_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    mhx_neural_sequence seq;
    logic [31:0] weight_patterns[] = '{
      32'h00000000,  // All -1 weights
      32'h55555555,  // All 0 weights
      32'hAAAAAAAA,  // All +1 weights
      32'h50A050A0,  // Alternating weights
      32'hA050A050   // Inverse alternating
    };
    logic [31:0] input_patterns[] = '{
      32'h00000000,  // All -1 inputs
      32'h55555555,  // All 0 inputs
      32'hAAAAAAAA,  // All +1 inputs
      32'h50A050A0,  // Alternating inputs
      32'hA050A050   // Inverse alternating
    };

    phase.raise_objection(this);
    `uvm_info("TEST", "Running neural weight patterns test", UVM_LOW)

    // Test all weight-input combinations for all neural operations
    foreach (weight_patterns[i]) begin
      foreach (input_patterns[j]) begin
        for (int op = 0; op < 4; op++) begin
          seq = mhx_neural_sequence::type_id::create("seq");
          seq.neural_operation = neural_op_e'(op);
          seq.weights = weight_patterns[i];
          seq.inputs = input_patterns[j];
          seq.bias = 32'h00000001;  // Small bias
          seq.start(env.agent.sequencer);

          // Also test with negative bias
          seq = mhx_neural_sequence::type_id::create("seq");
          seq.neural_operation = neural_op_e'(op);
          seq.weights = weight_patterns[i];
          seq.inputs = input_patterns[j];
          seq.bias = 32'h00000000;  // Negative bias
          seq.start(env.agent.sequencer);

          // And with positive bias
          seq = mhx_neural_sequence::type_id::create("seq");
          seq.neural_operation = neural_op_e'(op);
          seq.weights = weight_patterns[i];
          seq.inputs = input_patterns[j];
          seq.bias = 32'h00000002;  // Positive bias
          seq.start(env.agent.sequencer);
        end
      end
    end

    phase.drop_objection(this);
  endtask
endclass

// Directed test for boundary register addresses
class mhx_ternary_boundary_regs_test extends mhx_ternary_base_test;
  `uvm_component_utils(mhx_ternary_boundary_regs_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    mhx_ternary_sequence seq;
    int boundary_regs[] = '{0, 1, 7, 8, 15, 16, 23, 24, 31};

    phase.raise_objection(this);
    `uvm_info("TEST", "Running boundary register addresses test", UVM_LOW)

    // Test T0 special behavior (always zero)
    for (int op = 0; op < 7; op++) begin
      seq = mhx_ternary_sequence::type_id::create("seq");
      seq.ternary_operation = ternary_op_e'(op);
      seq.ternary_rs1 = 0;  // T0 source
      seq.ternary_rs2 = 0;  // T0 source
      seq.ternary_rd = 0;   // T0 destination (should be no-op)
      seq.start(env.agent.sequencer);
    end

    // Test all boundary register combinations
    foreach (boundary_regs[i]) begin
      foreach (boundary_regs[j]) begin
        foreach (boundary_regs[k]) begin
          for (int op = 0; op < 7; op++) begin
            seq = mhx_ternary_sequence::type_id::create("seq");
            seq.ternary_operation = ternary_op_e'(op);
            seq.ternary_rs1 = boundary_regs[i];
            seq.ternary_rs2 = boundary_regs[j];
            seq.ternary_rd = boundary_regs[k];
            seq.start(env.agent.sequencer);
          end
        end
      end
    end

    phase.drop_objection(this);
  endtask
endclass

// Comprehensive coverage closure test suite
class mhx_coverage_closure_test extends mhx_ternary_base_test;
  `uvm_component_utils(mhx_coverage_closure_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    `uvm_info("TEST", "========================================", UVM_LOW)
    `uvm_info("TEST", "Running Comprehensive Coverage Closure", UVM_LOW)
    `uvm_info("TEST", "========================================", UVM_LOW)

    // Run all directed test sequences
    begin
      mhx_ternary_all_ops_test all_ops;
      mhx_ternary_corner_cases_test corner;
      mhx_ternary_overflow_test overflow;
      mhx_ternary_back_to_back_test b2b;
      mhx_ternary_neural_interaction_test interaction;
      mhx_ternary_hazards_test hazards;
      mhx_neural_weight_patterns_test weights;
      mhx_ternary_boundary_regs_test boundary;

      all_ops = mhx_ternary_all_ops_test::type_id::create("all_ops", this);
      corner = mhx_ternary_corner_cases_test::type_id::create("corner", this);
      overflow = mhx_ternary_overflow_test::type_id::create("overflow", this);
      b2b = mhx_ternary_back_to_back_test::type_id::create("b2b", this);
      interaction = mhx_ternary_neural_interaction_test::type_id::create("interaction", this);
      hazards = mhx_ternary_hazards_test::type_id::create("hazards", this);
      weights = mhx_neural_weight_patterns_test::type_id::create("weights", this);
      boundary = mhx_ternary_boundary_regs_test::type_id::create("boundary", this);

      fork
        all_ops.run_phase(phase);
        corner.run_phase(phase);
        overflow.run_phase(phase);
        b2b.run_phase(phase);
        interaction.run_phase(phase);
        hazards.run_phase(phase);
        weights.run_phase(phase);
        boundary.run_phase(phase);
      join

      `uvm_info("TEST", "========================================", UVM_LOW)
      `uvm_info("TEST", "Coverage Closure Tests Completed", UVM_LOW)
      `uvm_info("TEST", "========================================", UVM_LOW)
    end

    phase.drop_objection(this);
  endtask
endclass
