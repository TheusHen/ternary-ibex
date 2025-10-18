// MHX Ternary UVM Sequences
// Collection of test sequences for different verification scenarios

// Base sequence class
class mhx_ternary_base_sequence extends uvm_sequence #(mhx_ternary_transaction);
  `uvm_object_utils(mhx_ternary_base_sequence)

  // Configuration access
  mhx_ternary_config cfg;

  // Sequence parameters
  rand int num_transactions;
  constraint c_num_transactions { num_transactions inside {[10:100]}; }

  function new(string name = "mhx_ternary_base_sequence");
    super.new(name);
  endfunction

  virtual task pre_body();
    super.pre_body();
    if (starting_phase != null) begin
      starting_phase.raise_objection(this, "Starting sequence");
    end

    // Get configuration
    if (!uvm_config_db#(mhx_ternary_config)::get(m_sequencer, "", "cfg", cfg)) begin
      uvm_report_warning("SEQ", "Configuration not found, using defaults");
      cfg = mhx_ternary_config::type_id::create("default_cfg");
    end
  endtask

  virtual task post_body();
    super.post_body();
    if (starting_phase != null) begin
      starting_phase.drop_objection(this, "Ending sequence");
    end
  endtask

  // Utility function to create and randomize transaction
  virtual function mhx_ternary_transaction create_transaction();
    mhx_ternary_transaction tr = mhx_ternary_transaction::type_id::create("tr");
    if (!tr.randomize()) begin
      `uvm_error("SEQ", "Failed to randomize transaction");
    end
    return tr;
  endfunction

endclass : mhx_ternary_base_sequence

// Random test sequence
class mhx_ternary_random_sequence extends mhx_ternary_base_sequence;
  `uvm_object_utils(mhx_ternary_random_sequence)

  constraint c_num_transactions { num_transactions == cfg.num_transactions; }

  function new(string name = "mhx_ternary_random_sequence");
    super.new(name);
  endfunction

  virtual task body();
    mhx_ternary_transaction tr;

    `uvm_info(
      "SEQ",
      $sformatf("Starting random sequence with %0d transactions", num_transactions),
      UVM_LOW
    );

    repeat(num_transactions) begin
      tr = create_transaction();
      start_item(tr);
      finish_item(tr);

      // Track transaction
      if (p_sequencer != null) begin
        mhx_ternary_sequencer seqr;
        if ($cast(seqr, p_sequencer)) begin
          seqr.record_transaction(tr);
        end
      end
    end

    `uvm_info("SEQ", "Random sequence completed", UVM_LOW);
  endtask

endclass : mhx_ternary_random_sequence

// Directed test sequence for all ternary operations
class mhx_ternary_operations_sequence extends mhx_ternary_base_sequence;
  `uvm_object_utils(mhx_ternary_operations_sequence)

  function new(string name = "mhx_ternary_operations_sequence");
    super.new(name);
  endfunction

  virtual task body();
    mhx_ternary_transaction tr;

    `uvm_info("SEQ", "Starting directed ternary operations sequence", UVM_LOW);

    // Test each ternary operation multiple times
    foreach (ternary_op_e op) begin
      repeat(10) begin
        tr = create_transaction();
        tr.is_ternary = 1'b1;
        tr.is_neural = 1'b0;
        tr.ternary_operation = ternary_op_e'(op);

        // Re-randomize other fields
        if (!tr.randomize(ternary_operation, is_ternary, is_neural)) begin
          `uvm_error("SEQ", "Failed to randomize transaction fields");
        end

        start_item(tr);
        finish_item(tr);

        `uvm_info(
          "SEQ",
          $sformatf("Sent %s operation", tr.ternary_operation.name()),
          UVM_HIGH
        );
      end
    end

    `uvm_info("SEQ", "Directed ternary operations sequence completed", UVM_LOW);
  endtask

endclass : mhx_ternary_operations_sequence

// Neural operations sequence
class mhx_ternary_neural_sequence extends mhx_ternary_base_sequence;
  `uvm_object_utils(mhx_ternary_neural_sequence)

  function new(string name = "mhx_ternary_neural_sequence");
    super.new(name);
  endfunction

  virtual task body();
    mhx_ternary_transaction tr;

    `uvm_info("SEQ", "Starting neural operations sequence", UVM_LOW);

    // Test each neural operation
    foreach (neural_op_e op) begin
      repeat(10) begin
        tr = create_transaction();
        tr.is_neural = 1'b1;
        tr.is_ternary = 1'b0;
        tr.neural_operation = neural_op_e'(op);

        // Re-randomize other fields
        if (!tr.randomize(neural_operation, is_ternary, is_neural)) begin
          `uvm_error("SEQ", "Failed to randomize transaction fields");
        end

        start_item(tr);
        finish_item(tr);

        `uvm_info(
          "SEQ",
          $sformatf("Sent %s operation", tr.neural_operation.name()),
          UVM_HIGH
        );
      end
    end

    `uvm_info("SEQ", "Neural operations sequence completed", UVM_LOW);
  endtask

endclass : mhx_ternary_neural_sequence

// Corner case sequence
class mhx_ternary_corner_sequence extends mhx_ternary_base_sequence;
  `uvm_object_utils(mhx_ternary_corner_sequence)

  function new(string name = "mhx_ternary_corner_sequence");
    super.new(name);
  endfunction

  virtual task body();
    mhx_ternary_transaction tr;

    `uvm_info("SEQ", "Starting corner case sequence", UVM_LOW);

    // Test extreme operand values
    test_extreme_values();

    // Test overflow conditions
    test_overflow_conditions();

    // Test register conflicts
    test_register_conflicts();

    `uvm_info("SEQ", "Corner case sequence completed", UVM_LOW);
  endtask

  virtual task test_extreme_values();
    mhx_ternary_transaction tr;
    logic [31:0] extreme_values[] = '{
      32'h00000000, // All -1
      32'h55555555, // All 0
      32'hAAAAAAAA, // All +1
      32'h50A050A0, // Alternating pattern
      32'hA050A050  // Opposite alternating
    };

    `uvm_info("SEQ", "Testing extreme operand values", UVM_MEDIUM);

    foreach (extreme_values[i]) begin
      foreach (extreme_values[j]) begin
        tr = create_transaction();
        tr.operand_a = extreme_values[i];
        tr.operand_b = extreme_values[j];
        tr.is_ternary = 1'b1;
        tr.is_neural = 1'b0;

        if (!tr.randomize(operand_a, operand_b, is_ternary, is_neural)) begin
          `uvm_error("SEQ", "Failed to randomize transaction");
        end

        start_item(tr);
        finish_item(tr);
      end
    end
  endtask

  virtual task test_overflow_conditions();
    mhx_ternary_transaction tr;

    `uvm_info("SEQ", "Testing overflow conditions", UVM_MEDIUM);

    // Test addition overflow: +1 + +1 = overflow
    repeat(5) begin
      tr = create_transaction();
      tr.operand_a = 32'hAAAAAAAA; // All +1
      tr.operand_b = 32'hAAAAAAAA; // All +1
      tr.ternary_operation = TERNARY_ADD;
      tr.is_ternary = 1'b1;
      tr.is_neural = 1'b0;

      if (!tr.randomize(operand_a, operand_b, ternary_operation, is_ternary, is_neural)) begin
        `uvm_error("SEQ", "Failed to randomize overflow transaction");
      end

      start_item(tr);
      finish_item(tr);
    end

    // Test subtraction underflow: -1 - +1 = underflow
    repeat(5) begin
      tr = create_transaction();
      tr.operand_a = 32'h00000000; // All -1
      tr.operand_b = 32'hAAAAAAAA; // All +1
      tr.ternary_operation = TERNARY_SUB;
      tr.is_ternary = 1'b1;
      tr.is_neural = 1'b0;

      if (!tr.randomize(operand_a, operand_b, ternary_operation, is_ternary, is_neural)) begin
        `uvm_error("SEQ", "Failed to randomize underflow transaction");
      end

      start_item(tr);
      finish_item(tr);
    end
  endtask

  virtual task test_register_conflicts();
    mhx_ternary_transaction tr;

    `uvm_info("SEQ", "Testing register conflicts", UVM_MEDIUM);

    // Test same source and destination registers
    repeat(10) begin
      tr = create_transaction();
      tr.ternary_rs1 = 4'h5;
      tr.ternary_rs2 = 4'h5;
      tr.ternary_rd = 4'h5;
      tr.is_ternary = 1'b1;
      tr.is_neural = 1'b0;

      if (!tr.randomize(ternary_rs1, ternary_rs2, ternary_rd, is_ternary, is_neural)) begin
        `uvm_error("SEQ", "Failed to randomize register conflict transaction");
      end

      start_item(tr);
      finish_item(tr);
    end
  endtask

endclass : mhx_ternary_corner_sequence

// Stress test sequence
class mhx_ternary_stress_sequence extends mhx_ternary_base_sequence;
  `uvm_object_utils(mhx_ternary_stress_sequence)

  constraint c_num_transactions { num_transactions == cfg.num_transactions * 5; } // 5x normal load

  function new(string name = "mhx_ternary_stress_sequence");
    super.new(name);
  endfunction

  virtual task body();
    mhx_ternary_transaction tr;

    `uvm_info(
      "SEQ",
      $sformatf("Starting stress sequence with %0d transactions", num_transactions),
      UVM_LOW
    );

    fork
      // High-frequency ternary operations
      begin
        repeat(num_transactions / 2) begin
          tr = create_transaction();
          tr.is_ternary = 1'b1;
          tr.is_neural = 1'b0;

          if (!tr.randomize(is_ternary, is_neural)) begin
            `uvm_error("SEQ", "Failed to randomize ternary transaction");
          end

          start_item(tr);
          finish_item(tr);

          // Minimal delay for stress
          #1;
        end
      end

      // Concurrent neural operations
      begin
        repeat(num_transactions / 2) begin
          tr = create_transaction();
          tr.is_neural = 1'b1;
          tr.is_ternary = 1'b0;

          if (!tr.randomize(is_ternary, is_neural)) begin
            `uvm_error("SEQ", "Failed to randomize neural transaction");
          end

          start_item(tr);
          finish_item(tr);

          // Minimal delay for stress
          #1;
        end
      end
    join

    `uvm_info("SEQ", "Stress sequence completed", UVM_LOW);
  endtask

endclass : mhx_ternary_stress_sequence

// Coverage-driven sequence
class mhx_ternary_coverage_sequence extends mhx_ternary_base_sequence;
  `uvm_object_utils(mhx_ternary_coverage_sequence)

  // Coverage-specific constraints
  constraint c_coverage_focused {
    num_transactions inside {[500:2000]};
  }

  function new(string name = "mhx_ternary_coverage_sequence");
    super.new(name);
  endfunction

  virtual task body();
    mhx_ternary_transaction tr;
    int coverage_transactions = 0;
    real target_coverage = cfg.coverage_goal;

    `uvm_info(
      "SEQ",
      $sformatf("Starting coverage-driven sequence (target: %0.1f%%)", target_coverage),
      UVM_LOW
    );

    // Run until coverage goal is met or max transactions reached
    while (coverage_transactions < num_transactions) begin
      tr = create_transaction();

      // Bias towards uncovered scenarios (simplified heuristic)
      if (coverage_transactions % 50 == 0) begin
        focus_on_uncovered_scenarios(tr);
      end

      start_item(tr);
      finish_item(tr);

      coverage_transactions++;

      // Check coverage periodically
      if (coverage_transactions % 100 == 0) begin
        `uvm_info(
          "SEQ",
          $sformatf("Coverage sequence progress: %0d transactions", coverage_transactions),
          UVM_MEDIUM
        );
      end
    end

    `uvm_info(
      "SEQ",
      $sformatf("Coverage sequence completed with %0d transactions", coverage_transactions),
      UVM_LOW
    );
  endtask

  // Focus on scenarios that might not be well covered
  virtual function void focus_on_uncovered_scenarios(mhx_ternary_transaction tr);
    // This is a simplified heuristic - in practice, you would query
    // the coverage database to find uncovered bins

    case ($urandom_range(0, 3))
      0: begin // Focus on specific operations
        tr.is_ternary = 1'b1;
        tr.is_neural = 1'b0;
        tr.ternary_operation = TERNARY_XOR; // Less common operation
      end
      1: begin // Focus on register conflicts
        tr.ternary_rs1 = tr.ternary_rd;
        tr.ternary_rs2 = tr.ternary_rd;
      end
      2: begin // Focus on overflow scenarios
        tr.operand_a = 32'hAAAAAAAA;
        tr.operand_b = 32'hAAAAAAAA;
        tr.ternary_operation = TERNARY_ADD;
      end
      3: begin // Focus on neural operations
        tr.is_neural = 1'b1;
        tr.is_ternary = 1'b0;
        tr.neural_operation = NEURAL_LEARN; // Less common operation
      end
    endcase
  endfunction

endclass : mhx_ternary_coverage_sequence
// MHX Ternary UVM Sequences
// Collection of test sequences for different verification scenarios

// Base sequence class
class mhx_ternary_base_sequence extends uvm_sequence #(mhx_ternary_transaction);
  `uvm_object_utils(mhx_ternary_base_sequence)
  
  // Configuration access
  mhx_ternary_config cfg;
  
  // Sequence parameters
  rand int num_transactions;
  constraint c_num_transactions { num_transactions inside {[10:100]}; }
  
  function new(string name = "mhx_ternary_base_sequence");
    super.new(name);
  endfunction
  
  virtual task pre_body();
    super.pre_body();
    if (starting_phase != null) begin
      starting_phase.raise_objection(this, "Starting sequence");
    end
    
    // Get configuration
    if (!uvm_config_db#(mhx_ternary_config)::get(m_sequencer, "", "cfg", cfg)) begin
      uvm_report_warning("SEQ", "Configuration not found, using defaults");
      cfg = mhx_ternary_config::type_id::create("default_cfg");
    end
  endtask
  
  virtual task post_body();
    super.post_body();
    if (starting_phase != null) begin
      starting_phase.drop_objection(this, "Ending sequence");
    end
  endtask
  
  // Utility function to create and randomize transaction
  virtual function mhx_ternary_transaction create_transaction();
    mhx_ternary_transaction tr = mhx_ternary_transaction::type_id::create("tr");
    if (!tr.randomize()) begin
      `uvm_error("SEQ", "Failed to randomize transaction");
    end
    return tr;
  endfunction

endclass : mhx_ternary_base_sequence

// Random test sequence
class mhx_ternary_random_sequence extends mhx_ternary_base_sequence;
  `uvm_object_utils(mhx_ternary_random_sequence)
  
  constraint c_num_transactions { num_transactions == cfg.num_transactions; }
  
  function new(string name = "mhx_ternary_random_sequence");
    super.new(name);
  endfunction
  
  virtual task body();
    mhx_ternary_transaction tr;
    
    `uvm_info("SEQ", $sformatf("Starting random sequence with %0d transactions", num_transactions), UVM_LOW);
    
    repeat(num_transactions) begin
      tr = create_transaction();
      start_item(tr);
      finish_item(tr);
      
      // Track transaction
      if (p_sequencer != null) begin
        mhx_ternary_sequencer seqr;
        if ($cast(seqr, p_sequencer)) begin
          seqr.record_transaction(tr);
        end
      end
    end
    
    `uvm_info("SEQ", "Random sequence completed", UVM_LOW);
  endtask

endclass : mhx_ternary_random_sequence

// Directed test sequence for all ternary operations
class mhx_ternary_operations_sequence extends mhx_ternary_base_sequence;
  `uvm_object_utils(mhx_ternary_operations_sequence)
  
  function new(string name = "mhx_ternary_operations_sequence");
    super.new(name);
  endfunction
  
  virtual task body();
    mhx_ternary_transaction tr;
    
    `uvm_info("SEQ", "Starting directed ternary operations sequence", UVM_LOW);
    
    // Test each ternary operation multiple times
    foreach (ternary_op_e op) begin
      repeat(10) begin
        tr = create_transaction();
        tr.is_ternary = 1'b1;
        tr.is_neural = 1'b0;
        tr.ternary_operation = ternary_op_e'(op);
        
        // Re-randomize other fields
        if (!tr.randomize(ternary_operation, is_ternary, is_neural)) begin
          `uvm_error("SEQ", "Failed to randomize transaction fields");
        end
        
        start_item(tr);
        finish_item(tr);
        
        `uvm_info("SEQ", $sformatf("Sent %s operation", tr.ternary_operation.name()), UVM_HIGH);
      end
    end
    
    `uvm_info("SEQ", "Directed ternary operations sequence completed", UVM_LOW);
  endtask

endclass : mhx_ternary_operations_sequence

// Neural operations sequence
class mhx_ternary_neural_sequence extends mhx_ternary_base_sequence;
  `uvm_object_utils(mhx_ternary_neural_sequence)
  
  function new(string name = "mhx_ternary_neural_sequence");
    super.new(name);
  endfunction
  
  virtual task body();
    mhx_ternary_transaction tr;
    
    `uvm_info("SEQ", "Starting neural operations sequence", UVM_LOW);
    
    // Test each neural operation
    foreach (neural_op_e op) begin
      repeat(10) begin
        tr = create_transaction();
        tr.is_neural = 1'b1;
        tr.is_ternary = 1'b0;
        tr.neural_operation = neural_op_e'(op);
        
        // Re-randomize other fields
        if (!tr.randomize(neural_operation, is_ternary, is_neural)) begin
          `uvm_error("SEQ", "Failed to randomize transaction fields");
        end
        
        start_item(tr);
        finish_item(tr);
        
        `uvm_info("SEQ", $sformatf("Sent %s operation", tr.neural_operation.name()), UVM_HIGH);
      end
    end
    
    `uvm_info("SEQ", "Neural operations sequence completed", UVM_LOW);
  endtask

endclass : mhx_ternary_neural_sequence

// Corner case sequence
class mhx_ternary_corner_sequence extends mhx_ternary_base_sequence;
  `uvm_object_utils(mhx_ternary_corner_sequence)
  
  function new(string name = "mhx_ternary_corner_sequence");
    super.new(name);
  endfunction
  
  virtual task body();
    mhx_ternary_transaction tr;
    
    `uvm_info("SEQ", "Starting corner case sequence", UVM_LOW);
    
    // Test extreme operand values
    test_extreme_values();
    
    // Test overflow conditions
    test_overflow_conditions();
    
    // Test register conflicts
    test_register_conflicts();
    
    `uvm_info("SEQ", "Corner case sequence completed", UVM_LOW);
  endtask
  
  virtual task test_extreme_values();
    mhx_ternary_transaction tr;
    logic [31:0] extreme_values[] = {
      32'h00000000, // All -1
      32'h55555555, // All 0
      32'hAAAAAAAA, // All +1
      32'h50A050A0, // Alternating pattern
      32'hA050A050  // Opposite alternating
    };
    
    `uvm_info("SEQ", "Testing extreme operand values", UVM_MEDIUM);
    
    foreach (extreme_values[i]) begin
      foreach (extreme_values[j]) begin
        tr = create_transaction();
        tr.operand_a = extreme_values[i];
        tr.operand_b = extreme_values[j];
        tr.is_ternary = 1'b1;
        tr.is_neural = 1'b0;
        
        if (!tr.randomize(operand_a, operand_b, is_ternary, is_neural)) begin
          `uvm_error("SEQ", "Failed to randomize transaction");
        end
        
        start_item(tr);
        finish_item(tr);
      end
    end
  endtask
  
  virtual task test_overflow_conditions();
    mhx_ternary_transaction tr;
    
    `uvm_info("SEQ", "Testing overflow conditions", UVM_MEDIUM);
    
    // Test addition overflow: +1 + +1 = overflow
    repeat(5) begin
      tr = create_transaction();
      tr.operand_a = 32'hAAAAAAAA; // All +1
      tr.operand_b = 32'hAAAAAAAA; // All +1
      tr.ternary_operation = TERNARY_ADD;
      tr.is_ternary = 1'b1;
      tr.is_neural = 1'b0;
      
      if (!tr.randomize(operand_a, operand_b, ternary_operation, is_ternary, is_neural)) begin
        `uvm_error("SEQ", "Failed to randomize overflow transaction");
      end
      
      start_item(tr);
      finish_item(tr);
    end
    
    // Test subtraction underflow: -1 - +1 = underflow
    repeat(5) begin
      tr = create_transaction();
      tr.operand_a = 32'h00000000; // All -1
      tr.operand_b = 32'hAAAAAAAA; // All +1
      tr.ternary_operation = TERNARY_SUB;
      tr.is_ternary = 1'b1;
      tr.is_neural = 1'b0;
      
      if (!tr.randomize(operand_a, operand_b, ternary_operation, is_ternary, is_neural)) begin
        `uvm_error("SEQ", "Failed to randomize underflow transaction");
      end
      
      start_item(tr);
      finish_item(tr);
    end
  endtask
  
  virtual task test_register_conflicts();
    mhx_ternary_transaction tr;
    
    `uvm_info("SEQ", "Testing register conflicts", UVM_MEDIUM);
    
    // Test same source and destination registers
    repeat(10) begin
      tr = create_transaction();
      tr.ternary_rs1 = 4'h5;
      tr.ternary_rs2 = 4'h5;
      tr.ternary_rd = 4'h5;
      tr.is_ternary = 1'b1;
      tr.is_neural = 1'b0;
      
      if (!tr.randomize(ternary_rs1, ternary_rs2, ternary_rd, is_ternary, is_neural)) begin
        `uvm_error("SEQ", "Failed to randomize register conflict transaction");
      end
      
      start_item(tr);
      finish_item(tr);
    end
  endtask

endclass : mhx_ternary_corner_sequence

// Stress test sequence
class mhx_ternary_stress_sequence extends mhx_ternary_base_sequence;
  `uvm_object_utils(mhx_ternary_stress_sequence)
  
  constraint c_num_transactions { num_transactions == cfg.num_transactions * 5; } // 5x normal load
  
  function new(string name = "mhx_ternary_stress_sequence");
    super.new(name);
  endfunction
  
  virtual task body();
    mhx_ternary_transaction tr;
    
    `uvm_info("SEQ", $sformatf("Starting stress sequence with %0d transactions", num_transactions), UVM_LOW);
    
    fork
      // High-frequency ternary operations
      begin
        repeat(num_transactions / 2) begin
          tr = create_transaction();
          tr.is_ternary = 1'b1;
          tr.is_neural = 1'b0;
          
          if (!tr.randomize(is_ternary, is_neural)) begin
            `uvm_error("SEQ", "Failed to randomize ternary transaction");
          end
          
          start_item(tr);
          finish_item(tr);
          
          // Minimal delay for stress
          #1;
        end
      end
      
      // Concurrent neural operations
      begin
        repeat(num_transactions / 2) begin
          tr = create_transaction();
          tr.is_neural = 1'b1;
          tr.is_ternary = 1'b0;
          
          if (!tr.randomize(is_ternary, is_neural)) begin
            `uvm_error("SEQ", "Failed to randomize neural transaction");
          end
          
          start_item(tr);
          finish_item(tr);
          
          // Minimal delay for stress
          #1;
        end
      end
    join
    
    `uvm_info("SEQ", "Stress sequence completed", UVM_LOW);
  endtask

endclass : mhx_ternary_stress_sequence

// Coverage-driven sequence
class mhx_ternary_coverage_sequence extends mhx_ternary_base_sequence;
  `uvm_object_utils(mhx_ternary_coverage_sequence)
  
  // Coverage-specific constraints
  constraint c_coverage_focused {
    num_transactions inside {[500:2000]};
  }
  
  function new(string name = "mhx_ternary_coverage_sequence");
    super.new(name);
  endfunction
  
  virtual task body();
    mhx_ternary_transaction tr;
    int coverage_transactions = 0;
    real target_coverage = cfg.coverage_goal;
    
    `uvm_info("SEQ", $sformatf("Starting coverage-driven sequence (target: %0.1f%%)", target_coverage), UVM_LOW);
    
    // Run until coverage goal is met or max transactions reached
    while (coverage_transactions < num_transactions) begin
      tr = create_transaction();
      
      // Bias towards uncovered scenarios (simplified heuristic)
      if (coverage_transactions % 50 == 0) begin
        focus_on_uncovered_scenarios(tr);
      end
      
      start_item(tr);
      finish_item(tr);
      
      coverage_transactions++;
      
      // Check coverage periodically
      if (coverage_transactions % 100 == 0) begin
        `uvm_info("SEQ", $sformatf("Coverage sequence progress: %0d transactions", coverage_transactions), UVM_MEDIUM);
      end
    end
    
    `uvm_info("SEQ", $sformatf("Coverage sequence completed with %0d transactions", coverage_transactions), UVM_LOW);
  endtask
  
  // Focus on scenarios that might not be well covered
  virtual function void focus_on_uncovered_scenarios(mhx_ternary_transaction tr);
    // This is a simplified heuristic - in practice, you would query
    // the coverage database to find uncovered bins
    
    case ($urandom_range(0, 3))
      0: begin // Focus on specific operations
        tr.is_ternary = 1'b1;
        tr.is_neural = 1'b0;
        tr.ternary_operation = TERNARY_XOR; // Less common operation
      end
      1: begin // Focus on register conflicts
        tr.ternary_rs1 = tr.ternary_rd;
        tr.ternary_rs2 = tr.ternary_rd;
      end
      2: begin // Focus on overflow scenarios
        tr.operand_a = 32'hAAAAAAAA;
        tr.operand_b = 32'hAAAAAAAA;
        tr.ternary_operation = TERNARY_ADD;
      end
      3: begin // Focus on neural operations
        tr.is_neural = 1'b1;
        tr.is_ternary = 1'b0;
        tr.neural_operation = NEURAL_LEARN; // Less common operation
      end
    endcase
  endfunction

endclass : mhx_ternary_coverage_sequence
