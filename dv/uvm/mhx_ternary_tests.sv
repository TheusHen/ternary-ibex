// MHX Ternary UVM Tests
// Collection of test classes for different verification scenarios

// Base test class
class mhx_ternary_base_test extends uvm_test;
  `uvm_component_utils(mhx_ternary_base_test)
  
  // Environment
  mhx_ternary_env env;
  
  // Configuration
  mhx_ternary_config cfg;
  
  // Virtual interface
  virtual mhx_ternary_if vif;
  
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Get virtual interface
    if (!uvm_config_db#(virtual mhx_ternary_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("NOVIF", "Virtual interface not found in test");
    end
    
    // Create and configure environment
    cfg = mhx_ternary_config::type_id::create("cfg");
    cfg.vif = vif;
    configure_test();
    
    env = mhx_ternary_env::type_id::create("env", this);
    
    // Pass configuration to environment
    uvm_config_db#(mhx_ternary_config)::set(this, "env*", "cfg", cfg);
    
    `uvm_info("TEST", $sformatf("Starting test: %s", get_name()), UVM_LOW);
  endfunction
  
  // Virtual function for test-specific configuration
  virtual function void configure_test();
    cfg.configure_for_test("basic_test");
  endfunction
  
  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    `uvm_info("TEST", "Test environment elaboration completed", UVM_MEDIUM);
    print_topology();
  endfunction
  
  // Default run phase - can be overridden by derived tests
  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this, "Starting default test");
    
    // Wait for reset
    wait(vif.rst_ni === 1'b1);
    #100;
    
    // Run default sequence
    run_default_sequence();
    
    #1000; // Allow time for final transactions to complete
    
    phase.drop_objection(this, "Default test completed");
  endtask
  
  // Default sequence - override in derived tests
  virtual task run_default_sequence();
    mhx_ternary_random_sequence seq = mhx_ternary_random_sequence::type_id::create("default_seq");
    seq.start(env.agent.sequencer);
  endtask
  
  // Report test results
  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    
    `uvm_info("TEST_RESULT", "=== Test Summary ===", UVM_LOW);
    `uvm_info("TEST_RESULT", $sformatf("Test: %s", get_name()), UVM_LOW);
    
    if (env.agent.monitor.errors_detected == 0) begin
      `uvm_info("TEST_RESULT", "Status: PASSED (no errors detected)", UVM_LOW);
    end else begin
      `uvm_error("TEST_RESULT", $sformatf("Status: FAILED (%0d errors detected)", 
                                         env.agent.monitor.errors_detected));
    end
    
    `uvm_info("TEST_RESULT", "====================", UVM_LOW);
  endfunction

endclass : mhx_ternary_base_test

// Basic functionality test
class mhx_ternary_basic_test extends mhx_ternary_base_test;
  `uvm_component_utils(mhx_ternary_basic_test)
  
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  
  virtual function void configure_test();
    cfg.configure_for_test("basic_test");
    cfg.num_transactions = 100;
    cfg.enable_coverage = 1;
    cfg.enable_scoreboard = 1;
  endfunction
  
  virtual task run_default_sequence();
    mhx_ternary_operations_sequence ternary_seq = mhx_ternary_operations_sequence::type_id::create("ternary_seq");
    mhx_ternary_neural_sequence neural_seq = mhx_ternary_neural_sequence::type_id::create("neural_seq");
    
    `uvm_info("TEST", "Running basic functionality test", UVM_LOW);
    
    fork
      ternary_seq.start(env.agent.sequencer);
      neural_seq.start(env.agent.sequencer);
    join
  endtask

endclass : mhx_ternary_basic_test

// Random test with high transaction count
class mhx_ternary_random_test extends mhx_ternary_base_test;
  `uvm_component_utils(mhx_ternary_random_test)
  
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  
  virtual function void configure_test();
    cfg.configure_for_test("basic_test");
    cfg.num_transactions = 1000;
    cfg.enable_coverage = 1;
    cfg.enable_scoreboard = 1;
    cfg.verbosity_level = UVM_MEDIUM;
  endfunction
  
  virtual task run_default_sequence();
    mhx_ternary_random_sequence seq = mhx_ternary_random_sequence::type_id::create("random_seq");
    
    `uvm_info("TEST", "Running random test with 1000 transactions", UVM_LOW);
    
    seq.start(env.agent.sequencer);
  endtask

endclass : mhx_ternary_random_test

// Corner case test
class mhx_ternary_corner_test extends mhx_ternary_base_test;
  `uvm_component_utils(mhx_ternary_corner_test)
  
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  
  virtual function void configure_test();
    cfg.configure_for_test("basic_test");
    cfg.num_transactions = 200;
    cfg.enable_coverage = 1;
    cfg.enable_scoreboard = 1;
    cfg.enable_protocol_checks = 1;
  endfunction
  
  virtual task run_default_sequence();
    mhx_ternary_corner_sequence seq = mhx_ternary_corner_sequence::type_id::create("corner_seq");
    
    `uvm_info("TEST", "Running corner case test", UVM_LOW);
    
    seq.start(env.agent.sequencer);
  endtask

endclass : mhx_ternary_corner_test

// Coverage-driven test
class mhx_ternary_coverage_test extends mhx_ternary_base_test;
  `uvm_component_utils(mhx_ternary_coverage_test)
  
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  
  virtual function void configure_test();
    cfg.configure_for_test("coverage_test");
    cfg.coverage_goal = 95;
    cfg.enable_coverage = 1;
    cfg.enable_scoreboard = 1;
  endfunction
  
  virtual task run_default_sequence();
    mhx_ternary_coverage_sequence seq = mhx_ternary_coverage_sequence::type_id::create("coverage_seq");
    
    `uvm_info("TEST", "Running coverage-driven test", UVM_LOW);
    
    seq.start(env.agent.sequencer);
  endtask
  
  // Override to check coverage achievement
  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    
    if (cfg.enable_coverage && env.coverage != null) begin
      real final_coverage = env.coverage.get_coverage();
      if (final_coverage >= cfg.coverage_goal) begin
        `uvm_info("TEST_RESULT", $sformatf("Coverage goal achieved: %0.1f%% >= %0d%%", 
                                          final_coverage, cfg.coverage_goal), UVM_LOW);
      end else begin
        `uvm_warning("TEST_RESULT", $sformatf("Coverage goal not met: %0.1f%% < %0d%%", 
                                             final_coverage, cfg.coverage_goal));
      end
    end
  endfunction

endclass : mhx_ternary_coverage_test

// Stress test
class mhx_ternary_stress_test extends mhx_ternary_base_test;
  `uvm_component_utils(mhx_ternary_stress_test)
  
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  
  virtual function void configure_test();
    cfg.configure_for_test("stress_test");
    cfg.timeout_cycles = 200000; // Longer timeout for stress test
    cfg.enable_timing_checks = 1;
    cfg.enable_coverage = 1;
    cfg.enable_scoreboard = 1;
  endfunction
  
  virtual task run_default_sequence();
    mhx_ternary_stress_sequence seq = mhx_ternary_stress_sequence::type_id::create("stress_seq");
    
    `uvm_info("TEST", "Running stress test with high transaction load", UVM_LOW);
    
    seq.start(env.agent.sequencer);
  endtask

endclass : mhx_ternary_stress_test

// Error injection test
class mhx_ternary_error_test extends mhx_ternary_base_test;
  `uvm_component_utils(mhx_ternary_error_test)
  
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  
  virtual function void configure_test();
    cfg.configure_for_test("error_test");
    cfg.enable_error_injection = 1;
    cfg.error_injection_rate = 0.1; // 10% error rate
    cfg.inject_invalid_trits = 1;
    cfg.inject_overflow_conditions = 1;
    cfg.inject_protocol_violations = 1;
    cfg.enable_protocol_checks = 1;
  endfunction
  
  virtual task run_default_sequence();
    mhx_ternary_random_sequence seq = mhx_ternary_random_sequence::type_id::create("error_seq");
    
    `uvm_info("TEST", "Running error injection test", UVM_LOW);
    
    seq.start(env.agent.sequencer);
  endtask
  
  // Override report to expect some errors in this test
  virtual function void report_phase(uvm_phase phase);
    `uvm_info("TEST_RESULT", "=== Error Test Summary ===", UVM_LOW);
    `uvm_info("TEST_RESULT", $sformatf("Test: %s", get_name()), UVM_LOW);
    `uvm_info("TEST_RESULT", $sformatf("Errors detected: %0d (expected due to error injection)", 
                                      env.agent.monitor.errors_detected), UVM_LOW);
    
    // For error injection test, some errors are expected
    if (env.agent.monitor.errors_detected > 0) begin
      `uvm_info("TEST_RESULT", "Status: PASSED (errors detected as expected)", UVM_LOW);
    end else begin
      `uvm_warning("TEST_RESULT", "Status: WARNING (no errors detected, error injection might not be working)");
    end
    
    `uvm_info("TEST_RESULT", "===========================", UVM_LOW);
  endfunction

endclass : mhx_ternary_error_test

// Performance test
class mhx_ternary_performance_test extends mhx_ternary_base_test;
  `uvm_component_utils(mhx_ternary_performance_test)
  
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  
  virtual function void configure_test();
    cfg.configure_for_test("performance_test");
    cfg.enable_timing_checks = 1;
    cfg.max_latency_cycles = 3; // Tight latency requirement
    cfg.target_throughput = 0.8; // High throughput target
    cfg.enable_scoreboard = 1;
  endfunction
  
  virtual task run_default_sequence();
    mhx_ternary_random_sequence seq = mhx_ternary_random_sequence::type_id::create("perf_seq");
    
    `uvm_info("TEST", "Running performance test", UVM_LOW);
    
    seq.start(env.agent.sequencer);
  endtask
  
  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    
    // Additional performance reporting
    `uvm_info("PERF_RESULT", "=== Performance Results ===", UVM_LOW);
    `uvm_info("PERF_RESULT", $sformatf("Average latency: %0.1f cycles", 
                                      env.agent.monitor.average_latency), UVM_LOW);
    `uvm_info("PERF_RESULT", $sformatf("Min/Max latency: %0d/%0d cycles", 
                                      env.agent.monitor.min_latency, 
                                      env.agent.monitor.max_latency), UVM_LOW);
    
    if (env.agent.monitor.average_latency <= cfg.max_latency_cycles) begin
      `uvm_info("PERF_RESULT", "Latency target met", UVM_LOW);
    end else begin
      `uvm_warning("PERF_RESULT", "Latency target exceeded");
    end
    
    `uvm_info("PERF_RESULT", "===========================", UVM_LOW);
  endfunction

endclass : mhx_ternary_performance_test

// Regression test - combines multiple test aspects
class mhx_ternary_regression_test extends mhx_ternary_base_test;
  `uvm_component_utils(mhx_ternary_regression_test)
  
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  
  virtual function void configure_test();
    cfg.configure_for_test("coverage_test");
    cfg.num_transactions = 2000;
    cfg.coverage_goal = 90;
    cfg.timeout_cycles = 100000;
    cfg.enable_coverage = 1;
    cfg.enable_scoreboard = 1;
    cfg.enable_protocol_checks = 1;
    cfg.enable_timing_checks = 1;
  endfunction
  
  virtual task run_default_sequence();
    `uvm_info("TEST", "Running comprehensive regression test", UVM_LOW);
    
    fork
      // Basic operations
      begin
        mhx_ternary_operations_sequence ops_seq = mhx_ternary_operations_sequence::type_id::create("ops_seq");
        ops_seq.start(env.agent.sequencer);
      end
      
      // Neural operations
      begin
        mhx_ternary_neural_sequence neural_seq = mhx_ternary_neural_sequence::type_id::create("neural_seq");
        neural_seq.start(env.agent.sequencer);
      end
      
      // Corner cases
      begin
        mhx_ternary_corner_sequence corner_seq = mhx_ternary_corner_sequence::type_id::create("corner_seq");
        corner_seq.start(env.agent.sequencer);
      end
      
      // Random transactions
      begin
        mhx_ternary_random_sequence random_seq = mhx_ternary_random_sequence::type_id::create("random_seq");
        random_seq.start(env.agent.sequencer);
      end
    join
  endtask

endclass : mhx_ternary_regression_test
