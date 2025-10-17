// MHX Ternary UVM Environment
// Top-level verification environment containing all components

class mhx_ternary_env extends uvm_env;
  `uvm_component_utils(mhx_ternary_env)
  
  // Components
  mhx_ternary_agent      agent;
  mhx_ternary_scoreboard scoreboard;
  mhx_ternary_coverage   coverage;
  
  // Configuration
  mhx_ternary_config cfg;
  
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Get configuration
    if (!uvm_config_db#(mhx_ternary_config)::get(this, "", "cfg", cfg)) begin
      `uvm_fatal("NOCFG", "Configuration object not found in environment");
    end
    
    // Validate configuration
    if (!cfg.validate_config()) begin
      `uvm_fatal("BADCFG", "Invalid configuration");
    end
    
    cfg.print_config();
    
    // Create components
    agent = mhx_ternary_agent::type_id::create("agent", this);
    
    if (cfg.enable_scoreboard) begin
      scoreboard = mhx_ternary_scoreboard::type_id::create("scoreboard", this);
    end
    
    if (cfg.enable_coverage) begin
      coverage = mhx_ternary_coverage::type_id::create("coverage", this);
    end
    
    // Pass configuration to all components
    uvm_config_db#(mhx_ternary_config)::set(this, "*", "cfg", cfg);
  endfunction
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    // Connect analysis ports
    if (cfg.enable_scoreboard && scoreboard != null) begin
      agent.monitor.sb_ap.connect(scoreboard.sb_export);
    end
    
    if (cfg.enable_coverage && coverage != null) begin
      agent.monitor.cov_ap.connect(coverage.analysis_export);
    end
    
    `uvm_info("ENV", "Environment connections completed", UVM_MEDIUM);
  endfunction
  
  // Convenience function to run a sequence
  virtual task run_sequence(uvm_sequence_base seq);
    agent.run_sequence(seq);
  endtask
  
  // Environment status monitoring
  virtual task run_phase(uvm_phase phase);
    fork
      monitor_test_progress();
      monitor_coverage_progress();
      monitor_timeout();
    join_none
  endtask
  
  // Monitor overall test progress
  virtual task monitor_test_progress();
    int last_count = 0;
    int stall_cycles = 0;
    
    forever begin
      #1000; // Check every 1000 time units
      
      int current_count = agent.monitor.transactions_monitored;
      if (current_count == last_count) begin
        stall_cycles++;
        if (stall_cycles > 10) begin // No progress for 10 checks
          uvm_report_warning(
            "ENV",
            $sformatf("Test progress stalled at %0d transactions", current_count)
          );
          stall_cycles = 0; // Reset to avoid spam
        end
      end else begin
        stall_cycles = 0;
  `uvm_info("ENV",
      $sformatf("Test progress: %0d transactions completed", current_count),
      UVM_HIGH);
      end
      
      last_count = current_count;
    end
  endtask
  
  // Monitor coverage progress
  virtual task monitor_coverage_progress();
    if (!cfg.enable_coverage) return;
    
    real last_coverage = 0.0;
    
    forever begin
      #5000; // Check every 5000 time units
      
      real current_cov = coverage.get_coverage();
      if (current_cov > last_coverage + 5.0) begin // Report significant coverage increases
        `uvm_info("ENV", $sformatf("Coverage progress: %0.1f%% (target: %0d%%)", 
                                  current_cov, cfg.coverage_goal), UVM_MEDIUM);
      end
      
      if (coverage.is_coverage_complete()) begin
        `uvm_info("ENV", "Coverage goal achieved!", UVM_LOW);
        break;
      end
      
      last_coverage = current_cov;
    end
  endtask
  
  // Monitor for test timeout
  virtual task monitor_timeout();
    #(cfg.timeout_cycles * 10); // Assume 10ns clock period
    `uvm_fatal("TIMEOUT", $sformatf("Test timed out after %0d cycles", cfg.timeout_cycles));
  endtask
  
  // Check phase - validate final environment state
  virtual function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    
    // Check if minimum number of transactions were generated
    if (agent.monitor.transactions_monitored < 10) begin
      `uvm_error("ENV", $sformatf("Too few transactions monitored: %0d", 
                                 agent.monitor.transactions_monitored));
    end
    
    // Check coverage if enabled
    if (cfg.enable_coverage) begin
      real final_coverage = coverage.get_coverage();
      if (final_coverage < cfg.coverage_goal) begin
        uvm_report_warning(
          "ENV",
          $sformatf("Coverage goal not met: %0.1f%% < %0d%%",
                    final_coverage, cfg.coverage_goal)
        );
      end
    end
    
    // Check scoreboard results
    if (cfg.enable_scoreboard && scoreboard.mismatches > 0) begin
      `uvm_error("ENV", $sformatf("Scoreboard detected %0d mismatches", scoreboard.mismatches));
    end
  endfunction
  
  // Report environment summary
  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    
    `uvm_info("ENV_SUMMARY", "=== Environment Summary ===", UVM_LOW);
    `uvm_info("ENV_SUMMARY", $sformatf("Total transactions: %0d", agent.monitor.transactions_monitored), UVM_LOW);
    
    if (cfg.enable_scoreboard) begin
      real pass_rate = 100.0;
      if (scoreboard.transactions_compared > 0) begin
        pass_rate = (scoreboard.matches * 100.0) / scoreboard.transactions_compared;
      end
      `uvm_info("ENV_SUMMARY", $sformatf("Scoreboard pass rate: %0.1f%%", pass_rate), UVM_LOW);
    end
    
    if (cfg.enable_coverage) begin
      `uvm_info("ENV_SUMMARY", $sformatf("Final coverage: %0.1f%%", coverage.get_coverage()), UVM_LOW);
    end
    
    `uvm_info("ENV_SUMMARY", $sformatf("Errors detected: %0d", agent.monitor.errors_detected), UVM_LOW);
    `uvm_info("ENV_SUMMARY", "===========================", UVM_LOW);
  endfunction

endclass : mhx_ternary_env
