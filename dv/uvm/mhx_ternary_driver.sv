// MHX Ternary UVM Driver
// Drives transactions to the DUT through the virtual interface

class mhx_ternary_driver extends uvm_driver #(mhx_ternary_transaction);
  `uvm_component_utils(mhx_ternary_driver)
  
  // Virtual interface
  virtual mhx_ternary_if.driver vif;
  
  // Configuration
  mhx_ternary_config cfg;
  
  // Statistics
  int unsigned transactions_driven = 0;
  int unsigned cycles_busy = 0;
  int unsigned cycles_idle = 0;
  
  // Current transaction
  mhx_ternary_transaction current_tr;
  
  function new(string name, uvm_component parent);
    super.new(name, parent);
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
      drive_transactions();
      monitor_idle_cycles();
    join
  endtask
  
  // Main transaction driving loop
  virtual task drive_transactions();
    mhx_ternary_transaction tr;
    
    // Wait for reset deassertion
    wait(vif.rst_ni === 1'b1);
    @(vif.driver_cb);
    
    forever begin
      // Get next transaction from sequencer
      seq_item_port.get_next_item(tr);
      current_tr = tr;
      
      // Record start time
      tr.start_cycle = get_cycle_count();
      
      // Drive the transaction
      drive_transaction(tr);
      
      // Record end time and calculate latency
      tr.end_cycle = get_cycle_count();
      tr.latency = tr.end_cycle - tr.start_cycle;
      
      transactions_driven++;
      
      `uvm_info("DRV", $sformatf("Driven transaction #%0d: %s", 
                                transactions_driven, tr.convert2string()), UVM_HIGH);
      
      // Notify sequencer that item is done
      seq_item_port.item_done();
      
      // Optional: Add inter-transaction delay
      repeat ($urandom_range(0, 3)) @(vif.driver_cb);
    end
  endtask
  
  // Drive a single transaction
  virtual task drive_transaction(mhx_ternary_transaction tr);
    // Apply error injection if enabled
    if (cfg.enable_error_injection && should_inject_error()) begin
      inject_error(tr);
    end
    
    // Drive instruction to DUT
    vif.driver_cb.instr_valid_i <= 1'b1;
    vif.driver_cb.instr_rdata_i <= tr.instruction;
    vif.driver_cb.pc_id <= tr.pc;
    
    @(vif.driver_cb);
    
    // Wait for instruction to be accepted (decoded)
    wait(vif.ternary_en_id === 1'b1 || vif.neural_en_id === 1'b1);
    cycles_busy++;
    
    // Validate that DUT decoded instruction correctly
    validate_decode(tr);
    
    // Keep instruction valid for one more cycle, then deassert
    @(vif.driver_cb);
    vif.driver_cb.instr_valid_i <= 1'b0;
    vif.driver_cb.instr_rdata_i <= 32'h0;
    
    // Wait for operation to complete
    if (tr.is_ternary) begin
      wait(vif.ternary_alu_ready === 1'b1);
    end else if (tr.is_neural) begin
      wait(vif.neural_valid === 1'b1);
    end
    
    cycles_busy++;
    
    `uvm_info("DRV", $sformatf("Transaction completed in %0d cycles", tr.latency), UVM_MEDIUM);
  endtask
  
  // Validate that DUT decoded the instruction correctly
  virtual function void validate_decode(mhx_ternary_transaction tr);
    if (tr.is_ternary) begin
      if (vif.ternary_en_id !== 1'b1) begin
        `uvm_error("DRV", "Expected ternary_en_id to be asserted for ternary instruction");
        tr.error_detected = 1'b1;
        tr.error_message = "Ternary enable not asserted";
      end
      if (vif.ternary_op_id !== tr.ternary_operation) begin
        `uvm_error("DRV", $sformatf("Operation mismatch: expected %s, got %s",
                                   tr.ternary_operation.name(), vif.ternary_op_id.name()));
        tr.error_detected = 1'b1;
        tr.error_message = "Operation decode mismatch";
      end
    end
    
    if (tr.is_neural) begin
      if (vif.neural_en_id !== 1'b1) begin
        `uvm_error("DRV", "Expected neural_en_id to be asserted for neural instruction");
        tr.error_detected = 1'b1;
        tr.error_message = "Neural enable not asserted";
      end
      if (vif.neural_op_id !== tr.neural_operation) begin
        `uvm_error("DRV", $sformatf("Operation mismatch: expected %s, got %s",
                                   tr.neural_operation.name(), vif.neural_op_id.name()));
        tr.error_detected = 1'b1;
        tr.error_message = "Neural operation decode mismatch";
      end
    end
  endfunction
  
  // Error injection for robustness testing
  virtual function bit should_inject_error();
    return ($urandom_range(0, 999) < cfg.error_injection_rate * 1000);
  endfunction
  
  virtual function void inject_error(ref mhx_ternary_transaction tr);
    case ($urandom_range(0, 2))
      0: begin // Inject invalid trit
        if (cfg.inject_invalid_trits) begin
          int trit_pos = $urandom_range(0, 15);
          tr.operand_a[trit_pos*2 +: 2] = 2'b11; // Invalid trit encoding
          `uvm_info("DRV", $sformatf("Injected invalid trit at position %0d", trit_pos), UVM_MEDIUM);
        end
      end
      1: begin // Inject protocol violation
        if (cfg.inject_protocol_violations) begin
          tr.instruction[6:0] = 7'b1111111; // Invalid opcode
          `uvm_info("DRV", "Injected invalid opcode", UVM_MEDIUM);
        end
      end
      2: begin // Inject overflow condition
        if (cfg.inject_overflow_conditions) begin
          tr.operand_a = 32'hAAAAAAAA; // All +1
          tr.operand_b = 32'hAAAAAAAA; // All +1, will cause overflow in ADD
          `uvm_info("DRV", "Injected overflow condition", UVM_MEDIUM);
        end
      end
    endcase
  endfunction
  
  // Monitor idle cycles
  virtual task monitor_idle_cycles();
    forever begin
      @(vif.driver_cb);
      if (!vif.instr_valid_i) cycles_idle++;
    end
  endtask
  
  // Utility function to get current cycle count
  virtual function int unsigned get_cycle_count();
    return cycles_busy + cycles_idle;
  endfunction
  
  // Report phase
  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("DRV_STATS", "=== Driver Statistics ===", UVM_LOW);
    `uvm_info("DRV_STATS", $sformatf("Transactions driven: %0d", transactions_driven), UVM_LOW);
    `uvm_info("DRV_STATS", $sformatf("Busy cycles: %0d", cycles_busy), UVM_LOW);
    `uvm_info("DRV_STATS", $sformatf("Idle cycles: %0d", cycles_idle), UVM_LOW);
    if (cycles_busy + cycles_idle > 0) begin
      real utilization = (cycles_busy * 100.0) / (cycles_busy + cycles_idle);
      `uvm_info("DRV_STATS", $sformatf("Utilization: %0.1f%%", utilization), UVM_LOW);
    end
    `uvm_info("DRV_STATS", "========================", UVM_LOW);
  endfunction

endclass : mhx_ternary_driver
