// MHX Ternary UVM Agent
// Contains driver, monitor, and sequencer for coordinated operation

class mhx_ternary_agent extends uvm_agent;
  `uvm_component_utils(mhx_ternary_agent)

  // Components
  mhx_ternary_driver    driver;
  mhx_ternary_monitor   monitor;
  mhx_ternary_sequencer sequencer;

  // Configuration
  mhx_ternary_config cfg;

  // Analysis port from monitor
  uvm_analysis_port #(mhx_ternary_transaction) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Get configuration
    if (!uvm_config_db#(mhx_ternary_config)::get(this, "", "cfg", cfg)) begin
      `uvm_fatal("NOCFG", "Configuration object not found");
    end

    // Create components
    monitor = mhx_ternary_monitor::type_id::create("monitor", this);

    if (get_is_active() == UVM_ACTIVE) begin
      driver = mhx_ternary_driver::type_id::create("driver", this);
      sequencer = mhx_ternary_sequencer::type_id::create("sequencer", this);
    end

    // Pass configuration to components
    uvm_config_db#(mhx_ternary_config)::set(this, "*", "cfg", cfg);

    // Pass virtual interface to components
    uvm_config_db#(virtual mhx_ternary_if)::set(this, "*", "vif", cfg.vif);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    // Connect analysis port from monitor
    ap = monitor.ap;

    // Connect driver to sequencer if active
    if (get_is_active() == UVM_ACTIVE) begin
      driver.seq_item_port.connect(sequencer.seq_item_export);
    end

    `uvm_info("AGENT", $sformatf("Agent configured in %s mode",
                                  get_is_active() == UVM_ACTIVE ? "ACTIVE" : "PASSIVE"),
              UVM_MEDIUM);
  endfunction

  // Convenience function to start a sequence
  virtual task run_sequence(uvm_sequence_base seq);
    if (get_is_active() == UVM_ACTIVE) begin
      seq.start(sequencer);
    end else begin
      uvm_report_warning("AGENT", "Cannot start sequence on passive agent");
    end
  endtask

endclass : mhx_ternary_agent
