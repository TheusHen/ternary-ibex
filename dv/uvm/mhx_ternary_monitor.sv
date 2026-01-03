// MHX™ Ternary UVM Monitor
// Monitors DUT behavior and collects transactions for analysis

class mhx_ternary_monitor extends uvm_monitor;
  `uvm_component_utils(mhx_ternary_monitor)

  // Virtual interface
  virtual mhx_ternary_if.monitor vif;

  // Configuration
  mhx_ternary_config cfg;

  // Analysis ports for broadcasting collected transactions
  uvm_analysis_port #(mhx_ternary_transaction) ap;
  uvm_analysis_port #(mhx_ternary_transaction) sb_ap; // For scoreboard
  uvm_analysis_port #(mhx_ternary_transaction) cov_ap; // For coverage

  // Statistics
  int unsigned transactions_monitored = 0;
  int unsigned ternary_ops_seen = 0;
  int unsigned neural_ops_seen = 0;
  int unsigned errors_detected = 0;

  // Performance metrics
  real average_latency = 0.0;
  int min_latency = 999999;
  int max_latency = 0;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
    sb_ap = new("sb_ap", this);
    cov_ap = new("cov_ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(virtual mhx_ternary_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("NOVIF", "Virtual interface not found");
    end

    if (!uvm_config_db#(mhx_ternary_config)::get(this, "", "cfg", cfg)) begin
      `uvm_fatal("NOCFG", "Configuration object not found");
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    fork
      monitor_transactions();
      monitor_protocol_violations();
      monitor_performance();
    join
  endtask

  // Main monitoring loop
  virtual task monitor_transactions();
    mhx_ternary_transaction tr;

    // Wait for reset deassertion
    wait(vif.rst_ni === 1'b1);
    @(vif.monitor_cb);

    forever begin
      // Wait for instruction valid
      wait(vif.instr_valid_i === 1'b1);

      // Create and populate transaction
      tr = mhx_ternary_transaction::type_id::create("tr");
      collect_transaction(tr);

      // Broadcast to all analysis ports
      ap.write(tr);
      sb_ap.write(tr);
      cov_ap.write(tr);

      transactions_monitored++;
      if (tr.is_ternary) ternary_ops_seen++;
      if (tr.is_neural) neural_ops_seen++;
      if (tr.error_detected) errors_detected++;

      `uvm_info(
        "MON",
        $sformatf(
          "Monitored transaction #%0d: %s",
          transactions_monitored,
          tr.convert2string()
        ),
        UVM_HIGH
      );

      // Wait for next instruction
      @(vif.monitor_cb);
    end
  endtask

  // Collect all transaction information
  virtual task collect_transaction(mhx_ternary_transaction tr);
    int start_cycle, end_cycle;

    // Capture instruction details
    tr.instruction = vif.instr_rdata_i;
    tr.pc = vif.pc_id;
    tr.opcode = vif.instr_rdata_i[6:0];
    tr.funct3 = vif.instr_rdata_i[14:12];

    // Wait for decode
    @(vif.monitor_cb);

    // Capture operation type and register addresses
    tr.is_ternary = vif.ternary_en_id;
    tr.is_neural = vif.neural_en_id;

    if (tr.is_ternary) begin
      tr.ternary_operation = ternary_op_e'(vif.ternary_op_id);
      tr.ternary_rs1 = vif.ternary_raddr_a_id;
      tr.ternary_rs2 = vif.ternary_raddr_b_id;
      tr.ternary_rd = vif.ternary_waddr_id;
    end

    if (tr.is_neural) begin
      tr.neural_operation = neural_op_e'(vif.neural_op_id);
      tr.ternary_rs1 = vif.ternary_raddr_a_id;
      tr.ternary_rs2 = vif.ternary_raddr_b_id;
      tr.ternary_rd = vif.ternary_waddr_id;
    end

    start_cycle = get_cycle_count();
    tr.start_cycle = start_cycle;

    // Capture operands
    tr.operand_a = vif.ternary_rdata_a;
    tr.operand_b = vif.ternary_rdata_b;

    // Wait for operation completion
    if (tr.is_ternary) begin
      wait(vif.ternary_alu_ready === 1'b1);
      tr.result = vif.ternary_alu_result;
      tr.ready = vif.ternary_alu_ready;
      tr.overflow = vif.ternary_alu_overflow;
      tr.trit_overflow = vif.ternary_trit_overflow;
    end else if (tr.is_neural) begin
      wait(vif.neural_valid === 1'b1);
      tr.result = vif.neural_result;
      tr.valid = vif.neural_valid;
    end

    end_cycle = get_cycle_count();
    tr.end_cycle = end_cycle;
    tr.latency = end_cycle - start_cycle;

    // Update performance statistics
    update_performance_stats(tr.latency);

    // Validate transaction
    validate_transaction(tr);
  endtask

  // Protocol violation monitoring
  virtual task monitor_protocol_violations();
    forever begin
      @(vif.monitor_cb);

      // Check for invalid ternary data
      if (vif.ternary_en_id) begin
        if (!is_valid_ternary_data(vif.ternary_rdata_a)) begin
          `uvm_error(
            "MON",
            $sformatf("Invalid ternary data in operand A: 0x%08h", vif.ternary_rdata_a)
          );
          errors_detected++;
        end
        if (!is_valid_ternary_data(vif.ternary_rdata_b)) begin
          `uvm_error(
            "MON",
            $sformatf("Invalid ternary data in operand B: 0x%08h", vif.ternary_rdata_b)
          );
          errors_detected++;
        end
      end

      // Check for timing violations
      if (cfg.enable_timing_checks) begin
        check_timing_violations();
      end
    end
  endtask

  // Performance monitoring
  virtual task monitor_performance();
    int window_start = 0;
    int window_size = 1000; // Monitor performance over 1000 cycle windows
    int instructions_in_window = 0;

    forever begin
      repeat(window_size) @(vif.monitor_cb);

      if (instructions_in_window > 0) begin
        real ipc = real'(instructions_in_window) / real'(window_size);
        `uvm_info(
          "PERF",
          $sformatf(
            "Performance window: %0d instructions in %0d cycles (IPC: %0.3f)",
            instructions_in_window,
            window_size,
            ipc
          ),
          UVM_MEDIUM
        );

        if (ipc < cfg.target_throughput) begin
          uvm_report_warning(
            "PERF",
            $sformatf(
              "Performance below target: %0.3f < %0.3f",
              ipc,
              cfg.target_throughput
            )
          );
        end
      end

      instructions_in_window = 0;
    end
  endtask

  // Transaction validation
  virtual function void validate_transaction(mhx_ternary_transaction tr);
    // Check latency bounds
    if (tr.latency > cfg.max_latency_cycles) begin
      uvm_report_warning(
        "MON",
        $sformatf(
          "Transaction latency (%0d) exceeds maximum (%0d)",
          tr.latency,
          cfg.max_latency_cycles
        )
      );
      tr.error_detected = 1'b1;
      tr.error_message = "Latency violation";
    end

    // Validate result data
    if (tr.is_ternary && tr.ready) begin
      if (!is_valid_ternary_data(tr.result)) begin
        `uvm_error("MON", $sformatf("Invalid ternary result: 0x%08h", tr.result));
        tr.error_detected = 1'b1;
        tr.error_message = "Invalid result data";
      end
    end

    // Check for unexpected combinations
    if (tr.is_ternary && tr.is_neural) begin
      `uvm_error("MON", "Both ternary and neural operations enabled simultaneously");
      tr.error_detected = 1'b1;
      tr.error_message = "Multiple operation types";
    end
  endfunction

  // Timing violation checks
  virtual function void check_timing_violations();
    // Add specific timing checks based on your protocol
    // Example: Check setup/hold times, clock domain crossings, etc.
  endfunction

  // Utility functions
  virtual function bit is_valid_ternary_data(logic [31:0] data);
    for (int i = 0; i < 16; i++) begin
      logic [1:0] trit = data[i*2 +: 2];
      if (!(trit inside {2'b00, 2'b01, 2'b10})) return 1'b0;
    end
    return 1'b1;
  endfunction

  virtual function int get_cycle_count();
    // Simple cycle counter - could be more sophisticated
    static int cycle_count = 0;
    cycle_count++;
    return cycle_count;
  endfunction

  virtual function void update_performance_stats(int latency);
    if (latency < min_latency) min_latency = latency;
    if (latency > max_latency) max_latency = latency;

    // Update running average
    if (transactions_monitored == 0) begin
      average_latency = latency;
    end else begin
      average_latency =
          ((average_latency * transactions_monitored) + latency) /
          (transactions_monitored + 1);
    end
  endfunction

  // Report phase
  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("MON_STATS", "=== Monitor Statistics ===", UVM_LOW);
    `uvm_info(
      "MON_STATS",
      $sformatf("Transactions monitored: %0d", transactions_monitored),
      UVM_LOW
    );
    `uvm_info(
      "MON_STATS",
      $sformatf("Ternary operations: %0d", ternary_ops_seen),
      UVM_LOW
    );
    `uvm_info(
      "MON_STATS",
      $sformatf("Neural operations: %0d", neural_ops_seen),
      UVM_LOW
    );
    `uvm_info(
      "MON_STATS",
      $sformatf("Errors detected: %0d", errors_detected),
      UVM_LOW
    );
    `uvm_info(
      "MON_STATS",
      $sformatf("Average latency: %0.1f cycles", average_latency),
      UVM_LOW
    );
    `uvm_info(
      "MON_STATS",
      $sformatf("Min/Max latency: %0d/%0d cycles", min_latency, max_latency),
      UVM_LOW
    );
    `uvm_info("MON_STATS", "==========================", UVM_LOW);
  endfunction

endclass : mhx_ternary_monitor
