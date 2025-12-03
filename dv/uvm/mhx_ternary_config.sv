// MHX Ternary UVM Configuration Object
// Contains all configuration parameters for the verification environment

class mhx_ternary_config extends uvm_object;
  `uvm_object_utils(mhx_ternary_config)

  // Interface handle
  virtual mhx_ternary_if vif;

  // Configuration flags
  bit enable_coverage = 1;
  bit enable_scoreboard = 1;
  bit enable_protocol_checks = 1;
  bit enable_timing_checks = 1;
  bit enable_error_injection = 0;

  // Test parameters
  int num_transactions = 1000;
  int max_sequence_length = 50;
  int timeout_cycles = 10000;

  // Coverage configuration
  int coverage_goal = 90;
  bit functional_coverage_enable = 1;
  bit code_coverage_enable = 1;
  bit assertion_coverage_enable = 1;

  // Debug configuration
  int verbosity_level = UVM_MEDIUM;
  bit enable_transaction_recording = 1;
  bit enable_waveform_dump = 1;
  string log_file = "mhx_ternary_test.log";

  // Performance configuration
  int max_latency_cycles = 10;
  real target_throughput = 0.8; // Instructions per cycle

  // Error injection configuration (for robustness testing)
  real error_injection_rate = 0.01; // 1% error rate
  bit inject_invalid_trits = 0;
  bit inject_overflow_conditions = 0;
  bit inject_protocol_violations = 0;

  function new(string name = "mhx_ternary_config");
    super.new(name);
  endfunction

  // Configure based on test type
  function void configure_for_test(string test_name);
    case (test_name)
      "basic_test": begin
        num_transactions = 100;
        enable_error_injection = 0;
        verbosity_level = UVM_HIGH;
      end
      "stress_test": begin
        num_transactions = 10000;
        max_sequence_length = 100;
        timeout_cycles = 100000;
      end
      "coverage_test": begin
        num_transactions = 5000;
        coverage_goal = 95;
        enable_coverage = 1;
      end
      "error_test": begin
        num_transactions = 500;
        enable_error_injection = 1;
        error_injection_rate = 0.05;
        inject_invalid_trits = 1;
        inject_overflow_conditions = 1;
      end
      "performance_test": begin
        num_transactions = 2000;
        enable_timing_checks = 1;
        max_latency_cycles = 5;
        target_throughput = 0.9;
      end
      default: begin
        uvm_report_warning(
          "CONFIG",
          $sformatf("Unknown test type: %s, using default config", test_name)
        );
      end
    endcase
  endfunction

  // Validation function
  function bit validate_config();
    bit valid = 1;

    if (vif == null) begin
      `uvm_error("CONFIG", "Virtual interface not set");
      valid = 0;
    end

    if (num_transactions <= 0) begin
      `uvm_error("CONFIG", "Number of transactions must be positive");
      valid = 0;
    end

    if (coverage_goal < 0 || coverage_goal > 100) begin
      `uvm_error("CONFIG", "Coverage goal must be between 0 and 100");
      valid = 0;
    end

    if (error_injection_rate < 0.0 || error_injection_rate > 1.0) begin
      `uvm_error("CONFIG", "Error injection rate must be between 0.0 and 1.0");
      valid = 0;
    end

    return valid;
  endfunction

  // Print configuration
  function void print_config();
    `uvm_info("CONFIG", "=== MHX Ternary Test Configuration ===", UVM_LOW);
    `uvm_info("CONFIG", $sformatf("Transactions: %0d", num_transactions), UVM_LOW);
    `uvm_info("CONFIG", $sformatf("Coverage enabled: %b", enable_coverage), UVM_LOW);
    `uvm_info("CONFIG", $sformatf("Scoreboard enabled: %b", enable_scoreboard), UVM_LOW);
    `uvm_info("CONFIG", $sformatf("Error injection: %b (rate: %0.2f%%)",
                                   enable_error_injection, error_injection_rate*100), UVM_LOW);
    `uvm_info("CONFIG", $sformatf("Coverage goal: %0d%%", coverage_goal), UVM_LOW);
    `uvm_info("CONFIG", $sformatf("Max latency: %0d cycles", max_latency_cycles), UVM_LOW);
    `uvm_info("CONFIG", $sformatf("Target throughput: %0.2f IPC", target_throughput), UVM_LOW);
    `uvm_info("CONFIG", "=====================================", UVM_LOW);
  endfunction

endclass : mhx_ternary_config
