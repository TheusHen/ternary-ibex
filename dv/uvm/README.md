# MHX Ternary Extensions UVM Testbench

This directory contains a comprehensive UVM (Universal Verification Methodology) testbench for verifying the MHX Ternary Extensions to the Ibex RISC-V core.

## Overview

The testbench provides:
- **Complete UVM Environment**: Agent, monitor, driver, sequencer, scoreboard, and coverage collector
- **Comprehensive Test Suite**: 8 different test types covering functionality, performance, and corner cases
- **Advanced Coverage Collection**: Functional coverage for all ternary and neural operations
- **Reference Model**: Golden reference for result checking
- **Multiple Simulators**: Support for Questa, VCS, and Xcelium
- **Automated Regression**: Multi-seed regression testing

## Directory Structure

```
dv/uvm/
├── mhx_ternary_pkg.sv           # Main UVM package with all includes
├── mhx_ternary_if.sv            # Virtual interface
├── mhx_ternary_tb_top.sv        # Testbench top module
├── mhx_ternary_transaction.sv   # Transaction class
├── mhx_ternary_config.sv        # Configuration object
├── mhx_ternary_sequencer.sv     # Sequencer
├── mhx_ternary_driver.sv        # Driver
├── mhx_ternary_monitor.sv       # Monitor
├── mhx_ternary_agent.sv         # Agent
├── mhx_ternary_scoreboard.sv    # Scoreboard with reference model
├── mhx_ternary_coverage.sv      # Coverage collector
├── mhx_ternary_env.sv           # Environment
├── mhx_ternary_sequences.sv     # Test sequences
├── mhx_ternary_tests.sv         # Test classes
├── Makefile                     # Build and run automation
└── README.md                    # This file
```

## Test Types

### 1. Basic Test (`mhx_ternary_basic_test`)
- Verifies fundamental ternary and neural operations
- Tests all 7 ternary operations and 4 neural operations
- 100 transactions with full scoreboard checking

### 2. Random Test (`mhx_ternary_random_test`)
- High-volume random transaction generation
- 1000 transactions with full coverage collection
- Stresses all operation combinations

### 3. Corner Case Test (`mhx_ternary_corner_test`)
- Tests extreme operand values (all -1, all 0, all +1)
- Overflow and underflow conditions
- Register conflict scenarios
- Protocol violation detection

### 4. Coverage Test (`mhx_ternary_coverage_test`)
- Coverage-driven test with 95% goal
- Intelligent coverage hole filling
- Comprehensive functional coverage collection

### 5. Stress Test (`mhx_ternary_stress_test`)
- High-frequency transaction generation
- Concurrent ternary and neural operations
- Extended timeout for long-running scenarios

### 6. Error Injection Test (`mhx_ternary_error_test`)
- 10% error injection rate
- Invalid trit injection
- Protocol violation injection
- Robustness verification

### 7. Performance Test (`mhx_ternary_performance_test`)
- Latency requirement verification (≤3 cycles)
- Throughput target verification (≥0.8 IPC)
- Performance metrics collection

### 8. Regression Test (`mhx_ternary_regression_test`)
- Comprehensive test combining all aspects
- 2000 transactions across all scenarios
- Full coverage and scoreboard checking

## Coverage Specification

The testbench includes comprehensive functional coverage:

### Ternary Operations Coverage
- **Operation Types**: All 7 ternary operations (ADD, SUB, MUL, AND, OR, XOR, NOT)
- **Register Usage**: All 16 ternary registers in various combinations
- **Operand Patterns**: Extreme values, alternating patterns, random data
- **Result Patterns**: All possible result categories
- **Overflow Scenarios**: All overflow and underflow conditions
- **Cross Coverage**: Operation × operand patterns, register conflicts

### Neural Operations Coverage
- **Neural Types**: All 4 neural operations (MULTIPLY, ACCUMULATE, ACTIVATE, LEARN)
- **Weight Patterns**: Various weight configurations
- **Input Patterns**: Various input data patterns
- **Bias Values**: All bias configurations
- **Cross Coverage**: Operation × weight × input patterns

### Error Scenarios Coverage
- **Error Detection**: All error types and conditions
- **Protocol Violations**: Invalid opcodes, timing violations
- **Data Integrity**: Invalid trit detection, overflow handling

## Quick Start

### Prerequisites
- UVM-compliant simulator (Questa, VCS, or Xcelium)
- UVM library installation
- SystemVerilog-capable simulator

### Basic Usage

```bash
# Compile and run basic test with Questa
make test_basic SIM=questa

# Run coverage test with waves
make test_coverage WAVES=1 COVERAGE=1

# Run full regression suite
make regression

# Run specific test with custom seed
make test_random SEED=42 SIM=vcs

# Generate coverage report
make coverage_report
```

### Environment Variables

Set these environment variables:
```bash
export UVM_HOME=/path/to/uvm/installation
export QUESTA_HOME=/path/to/questa    # If using Questa
export VCS_HOME=/path/to/vcs          # If using VCS
export XCELIUM_HOME=/path/to/xcelium  # If using Xcelium
```

## Configuration Options

The testbench supports extensive configuration through `mhx_ternary_config`:

```systemverilog
// Example configuration
cfg.num_transactions = 1000;        // Number of transactions
cfg.coverage_goal = 95;              // Coverage target percentage
cfg.enable_error_injection = 1;     // Enable error injection
cfg.error_injection_rate = 0.05;    // 5% error rate
cfg.max_latency_cycles = 5;         // Maximum allowed latency
cfg.target_throughput = 0.8;        // Target instructions per cycle
```

## Advanced Usage

### Custom Test Development

To create a new test:

```systemverilog
class my_custom_test extends mhx_ternary_base_test;
  `uvm_component_utils(my_custom_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void configure_test();
    cfg.num_transactions = 500;
    cfg.enable_coverage = 1;
    // Add custom configuration
  endfunction

  virtual task run_default_sequence();
    my_custom_sequence seq = my_custom_sequence::type_id::create("seq");
    seq.start(env.agent.sequencer);
  endtask
endclass
```

### Custom Sequence Development

```systemverilog
class my_custom_sequence extends mhx_ternary_base_sequence;
  `uvm_object_utils(my_custom_sequence)

  virtual task body();
    mhx_ternary_transaction tr;

    repeat(50) begin
      tr = create_transaction();
      // Custom constraints/modifications
      tr.is_ternary = 1'b1;
      tr.ternary_operation = TERNARY_ADD;

      start_item(tr);
      finish_item(tr);
    end
  endtask
endclass
```

### Debug and Analysis

```bash
# Enable maximum verbosity and waves
make debug TEST=mhx_ternary_basic_test

# Run with specific verbosity level
make run VERBOSITY=UVM_HIGH

# Collect detailed coverage
make test_coverage COVERAGE=1

# Generate HTML coverage report
make coverage_report
```

## Integration with Actual DUT

To connect to your actual Ibex core with ternary extensions:

1. **Update `mhx_ternary_tb_top.sv`**:
   - Replace the placeholder DUT instantiation
   - Connect actual ternary extension ports
   - Map interface signals correctly

2. **Update `mhx_ternary_if.sv`**:
   - Add missing signal connections
   - Adjust signal widths if needed
   - Update clocking blocks

3. **Update RTL file list in Makefile**:
   - Add/remove RTL files as needed
   - Update include paths

Example DUT connection:
```systemverilog
// In mhx_ternary_tb_top.sv
ibex_core_with_ternary dut (
  .clk_i(clk),
  .rst_ni(rst_n),
  // ... standard Ibex ports ...

  // Ternary extension ports
  .ternary_en_id(vif.ternary_en_id),
  .neural_en_id(vif.neural_en_id),
  .ternary_op_id(vif.ternary_op_id),
  .neural_op_id(vif.neural_op_id),
  // ... other ternary signals ...
);
```

## Troubleshooting

### Common Issues

1. **"Virtual interface not found"**
   - Check that `vif` is properly set in `uvm_config_db`
   - Verify interface instantiation in testbench top

2. **"Configuration object not found"**
   - Ensure configuration is passed to all components
   - Check `uvm_config_db` usage in tests

3. **Compilation errors**
   - Verify UVM_HOME environment variable
   - Check SystemVerilog simulator compatibility
   - Ensure all RTL files are included

4. **No transactions generated**
   - Check clock and reset connectivity
   - Verify DUT is not stuck in reset
   - Enable higher verbosity for debugging

### Debug Tips

- Use `+UVM_VERBOSITY=UVM_DEBUG` for maximum detail
- Enable waveform dumping with `WAVES=1`
- Check log files in `logs/` directory
- Use simulator's debugging capabilities

## Performance Considerations

The testbench is designed for efficiency:
- Transactions are pre-allocated when possible
- Coverage sampling is optimized
- Minimal inter-transaction delays
- Configurable timeout values

Expected performance:
- Basic test: ~1-2 minutes
- Coverage test: ~5-10 minutes
- Regression test: ~15-30 minutes

## Contributing

When adding new features:
1. Follow existing coding style
2. Add appropriate coverage points
3. Update documentation
4. Test with multiple simulators
5. Add regression test if needed

## Support

For issues or questions:
1. Check this documentation
2. Review log files for error details
3. Enable debug mode for more information
4. Consult UVM documentation for methodology questions

---

**Note**: This testbench provides a solid foundation for ternary extension verification. Adapt the DUT connections and add project-specific tests as needed for your particular implementation.