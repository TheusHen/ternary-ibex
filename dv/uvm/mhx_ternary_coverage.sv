// MHX Ternary UVM Coverage Collector
// Collects functional coverage for ternary operations

class mhx_ternary_coverage extends uvm_subscriber #(mhx_ternary_transaction);
  `uvm_component_utils(mhx_ternary_coverage)

  // Configuration
  mhx_ternary_config cfg;

  // Coverage statistics
  int unsigned transactions_covered = 0;
  real current_coverage = 0.0;

  // Transaction for sampling
  mhx_ternary_transaction tr;

  // Coverage groups
  covergroup ternary_operations_cg;
  option.per_instance = 1;
  option.name = "ternary_operations";

    // Basic operation coverage
    cp_operation: coverpoint tr.ternary_operation {
      bins add = {TERNARY_ADD};
      bins sub = {TERNARY_SUB};
      bins mul = {TERNARY_MUL};
      bins and_op = {TERNARY_AND};
      bins or_op = {TERNARY_OR};
      bins xor_op = {TERNARY_XOR};
      bins not_op = {TERNARY_NOT};
  }

    // Register address coverage
    cp_rs1: coverpoint tr.ternary_rs1 {
      bins low_regs   = {[0:7]};   // T0-T7
      bins mid_regs   = {[8:15]};  // T8-T15
      bins high_regs  = {[16:23]}; // T16-T23
      bins upper_regs = {[24:31]}; // T24-T31
  }

    cp_rs2: coverpoint tr.ternary_rs2 {
      bins low_regs   = {[0:7]};   // T0-T7
      bins mid_regs   = {[8:15]};  // T8-T15
      bins high_regs  = {[16:23]}; // T16-T23
      bins upper_regs = {[24:31]}; // T24-T31
  }

    cp_rd: coverpoint tr.ternary_rd {
      bins low_regs   = {[0:7]};   // T0-T7
      bins mid_regs   = {[8:15]};  // T8-T15
      bins high_regs  = {[16:23]}; // T16-T23
      bins upper_regs = {[24:31]}; // T24-T31
  }

    // Operand patterns
    cp_operand_a_pattern: coverpoint tr.operand_a {
      bins all_neg  = {32'h00000000}; // All -1
      bins all_zero = {32'h55555555}; // All 0
      bins all_pos  = {32'hAAAAAAAA}; // All +1
      bins mixed    = default;
  }

    cp_operand_b_pattern: coverpoint tr.operand_b {
      bins all_neg  = {32'h00000000}; // All -1
      bins all_zero = {32'h55555555}; // All 0
      bins all_pos  = {32'hAAAAAAAA}; // All +1
      bins mixed    = default;
  }

    // Result patterns
    cp_result_pattern: coverpoint tr.result {
      bins all_neg  = {32'h00000000};
      bins all_zero = {32'h55555555};
      bins all_pos  = {32'hAAAAAAAA};
      bins mixed    = default;
  }

    // Overflow scenarios
    cp_overflow: coverpoint tr.overflow {
      bins no_overflow = {1'b0};
      bins overflow    = {1'b1};
  }

    // Latency coverage
    cp_latency: coverpoint tr.latency {
      bins single_cycle = {1};
      bins few_cycles   = {[2:5]};
      bins many_cycles  = {[6:$]};
    }

    // Cross coverage for comprehensive scenarios
    cx_op_overflow: cross cp_operation, cp_overflow;
    cx_op_patterns: cross cp_operation, cp_operand_a_pattern, cp_operand_b_pattern;
    cx_reg_usage: cross cp_rs1, cp_rs2, cp_rd {
      // Ensure we test same register for multiple operations
  bins same_src_diff_dst = binsof(cp_rs1) intersect binsof(cp_rs2) &&
           !binsof(cp_rd) intersect binsof(cp_rs1);
      bins diff_all = !binsof(cp_rs1) intersect binsof(cp_rs2) &&
                      !binsof(cp_rd) intersect binsof(cp_rs1) &&
                      !binsof(cp_rd) intersect binsof(cp_rs2);
    }
  endgroup

  covergroup neural_operations_cg;
  option.per_instance = 1;
  option.name = "neural_operations";

    // Neural operation coverage
    cp_neural_op: coverpoint tr.neural_operation {
      bins multiply   = {NEURAL_MULTIPLY};
      bins accumulate = {NEURAL_ACCUMULATE};
      bins activate   = {NEURAL_ACTIVATE};
      bins learn      = {NEURAL_LEARN};
  }

    // Neural-specific patterns
    cp_weights_pattern: coverpoint tr.operand_a {
      bins all_neg     = {32'h00000000};
      bins all_zero    = {32'h55555555};
      bins all_pos     = {32'hAAAAAAAA};
      bins alternating = {32'h50A050A0, 32'hA050A050};
      bins random      = default;
  }

    cp_inputs_pattern: coverpoint tr.operand_b {
      bins all_neg     = {32'h00000000};
      bins all_zero    = {32'h55555555};
      bins all_pos     = {32'hAAAAAAAA};
      bins alternating = {32'h50A050A0, 32'hA050A050};
      bins random      = default;
  }

  cp_bias_pattern: coverpoint tr.bias[1:0] {
      bins neg_bias  = {2'b00};
      bins zero_bias = {2'b01};
      bins pos_bias  = {2'b10};
  }

    // Valid signal coverage
    cp_valid: coverpoint tr.valid {
      bins not_valid = {1'b0};
      bins valid     = {1'b1};
    }

    // Cross coverage for neural operations
    cx_neural_weights_inputs: cross cp_neural_op, cp_weights_pattern, cp_inputs_pattern;
    cx_neural_bias: cross cp_neural_op, cp_bias_pattern;
  endgroup

  covergroup error_scenarios_cg;
  option.per_instance = 1;
  option.name = "error_scenarios";

    // Error detection coverage
    cp_error_detected: coverpoint tr.error_detected {
      bins no_error = {1'b0};
      bins error    = {1'b1};
  }

    // Types of errors (based on error message)
    cp_error_type: coverpoint tr.error_message {
      bins latency_violation = {"Latency violation"};
      bins invalid_result = {"Invalid result data"};
      bins decode_mismatch = {"Operation decode mismatch"};
      bins multiple_ops = {"Multiple operation types"};
      bins protocol_violation = default;
    }

    // Cross coverage
    cx_error_scenarios: cross cp_error_detected, cp_error_type;
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);

    // Create coverage groups
    ternary_operations_cg = new();
    neural_operations_cg = new();
    error_scenarios_cg = new();
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(mhx_ternary_config)::get(this, "", "cfg", cfg)) begin
      `uvm_fatal("NOCFG", "Configuration object not found");
    end
  endfunction

  // Main coverage collection function
  virtual function void write(mhx_ternary_transaction t);
    if (!cfg.enable_coverage) return;

    tr = t; // Assign for coverpoint sampling

    // Sample appropriate coverage groups
    if (t.is_ternary) begin
      ternary_operations_cg.sample();
    end

    if (t.is_neural) begin
      neural_operations_cg.sample();
    end

    // Always sample error scenarios
    error_scenarios_cg.sample();

    transactions_covered++;

    // Update coverage statistics periodically
    if (transactions_covered % 100 == 0) begin
      update_coverage_stats();
    end
  endfunction

  // Update coverage statistics
  virtual function void update_coverage_stats();
    real ternary_cov = ternary_operations_cg.get_inst_coverage();
    real neural_cov = neural_operations_cg.get_inst_coverage();
    real error_cov = error_scenarios_cg.get_inst_coverage();

    current_coverage = (ternary_cov + neural_cov + error_cov) / 3.0;

  `uvm_info("COV",
        $sformatf("Coverage update: Ternary=%0.1f%%, Neural=%0.1f%%, Errors=%0.1f%%, Overall=%0.1f%%",
            ternary_cov, neural_cov, error_cov, current_coverage),
        UVM_MEDIUM);

    // Check if coverage goal is met
    if (current_coverage >= cfg.coverage_goal) begin
  `uvm_info("COV", $sformatf("Coverage goal achieved: %0.1f%% >= %0d%%",
                                current_coverage, cfg.coverage_goal), UVM_LOW);
    end
  endfunction

  // Report detailed coverage
  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);

    if (!cfg.enable_coverage) return;

    update_coverage_stats();

    `uvm_info("COV_STATS", "=== Coverage Statistics ===", UVM_LOW);
    `uvm_info("COV_STATS", $sformatf("Transactions covered: %0d", transactions_covered), UVM_LOW);
    `uvm_info("COV_STATS", $sformatf("Ternary operations coverage: %0.1f%%",
                                    ternary_operations_cg.get_inst_coverage()), UVM_LOW);
    `uvm_info("COV_STATS", $sformatf("Neural operations coverage: %0.1f%%",
                                    neural_operations_cg.get_inst_coverage()), UVM_LOW);
    `uvm_info("COV_STATS", $sformatf("Error scenarios coverage: %0.1f%%",
                                    error_scenarios_cg.get_inst_coverage()), UVM_LOW);
    `uvm_info("COV_STATS", $sformatf("Overall coverage: %0.1f%%", current_coverage), UVM_LOW);

    // Report uncovered items
    report_uncovered_items();

    `uvm_info("COV_STATS", "===========================", UVM_LOW);
  endfunction

  // Report uncovered coverage items
  virtual function void report_uncovered_items();
    // This would typically use coverage database queries
    // For now, provide basic reporting framework

    if (ternary_operations_cg.get_inst_coverage() < 100.0) begin
      uvm_report_warning("COV", "Some ternary operation scenarios not covered");
    end

    if (neural_operations_cg.get_inst_coverage() < 100.0) begin
      uvm_report_warning("COV", "Some neural operation scenarios not covered");
    end

    if (error_scenarios_cg.get_inst_coverage() < 100.0) begin
      `uvm_info("COV", "Some error scenarios not covered (this may be expected)", UVM_MEDIUM);
    end
  endfunction

  // Get current coverage for external queries
  virtual function real get_coverage();
    return current_coverage;
  endfunction

  // Check if coverage goal is met
  virtual function bit is_coverage_complete();
    return (current_coverage >= cfg.coverage_goal);
  endfunction

endclass : mhx_ternary_coverage
