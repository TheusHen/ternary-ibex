// MHX Ternary UVM Sequencer
// Manages sequence execution and transaction flow

class mhx_ternary_sequencer extends uvm_sequencer #(mhx_ternary_transaction);
  `uvm_component_utils(mhx_ternary_sequencer)

  // Configuration object
  mhx_ternary_config cfg;

  // Statistics
  int unsigned transactions_sent = 0;
  int unsigned ternary_ops_sent = 0;
  int unsigned neural_ops_sent = 0;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(mhx_ternary_config)::get(this, "", "cfg", cfg)) begin
      `uvm_fatal("NOCFG", "Configuration object not found");
    end
  endfunction

  // Custom sequence execution with statistics tracking
  virtual task execute_sequence(uvm_sequence_base seq);
    int start_count = transactions_sent;
    seq.start(this);
    int end_count = transactions_sent;
    `uvm_info(
      "SEQR",
      $sformatf(
        "Sequence %s executed %0d transactions",
        seq.get_name(),
        end_count - start_count
      ),
      UVM_MEDIUM
    );
  endtask

  // Transaction accounting (called by sequences)
  virtual function void record_transaction(mhx_ternary_transaction tr);
    transactions_sent++;
    if (tr.is_ternary) ternary_ops_sent++;
    if (tr.is_neural) neural_ops_sent++;
  endfunction

  // Report statistics
  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("SEQR_STATS", "=== Sequencer Statistics ===", UVM_LOW);
    `uvm_info(
      "SEQR_STATS",
      $sformatf("Total transactions: %0d", transactions_sent),
      UVM_LOW
    );
    `uvm_info(
      "SEQR_STATS",
      $sformatf("Ternary operations: %0d", ternary_ops_sent),
      UVM_LOW
    );
    `uvm_info(
      "SEQR_STATS",
      $sformatf("Neural operations: %0d", neural_ops_sent),
      UVM_LOW
    );
    if (transactions_sent > 0) begin
      `uvm_info(
        "SEQR_STATS",
        $sformatf(
          "Ternary ratio: %0.1f%%",
          (ternary_ops_sent * 100.0) / transactions_sent
        ),
        UVM_LOW
      );
      `uvm_info(
        "SEQR_STATS",
        $sformatf(
          "Neural ratio: %0.1f%%",
          (neural_ops_sent * 100.0) / transactions_sent
        ),
        UVM_LOW
      );
    end
    `uvm_info("SEQR_STATS", "============================", UVM_LOW);
  endfunction

endclass : mhx_ternary_sequencer
