# MHX Ternary Extension - Debug and Development Guide

**Version:** 1.0
**Date:** September 29, 2025
**Authors:** MHX Neural Development Team

## Table of Contents
1. [Overview](#1-overview)
2. [Debug Environment Setup](#2-debug-environment-setup)
3. [Ternary ALU Debugging](#3-ternary-alu-debugging)
4. [Neural Unit Debugging](#4-neural-unit-debugging)
5. [Register File Debugging](#5-register-file-debugging)
6. [Integration Debugging](#6-integration-debugging)
7. [Common Issues and Solutions](#7-common-issues-and-solutions)
8. [Performance Analysis](#8-performance-analysis)
9. [Simulation and Testing](#9-simulation-and-testing)
10. [Hardware Debug](#10-hardware-debug)

## 1. Overview

This guide provides comprehensive debugging information for the MHX Ternary Extension to the Ibex RISC-V core. It covers debugging techniques, common issues, performance analysis, and troubleshooting procedures for all ternary components.

### 1.1 Debug Scope

The MHX Ternary Extension includes:
- **Ternary ALU**: 7 arithmetic/logic operations with overflow handling
- **Neural Unit**: 4 neural operations with accumulator
- **Ternary Register File**: 16 registers with dual-port access
- **Decoder Integration**: Custom opcode support
- **Core Integration**: Signal routing and control logic

### 1.2 Debug Levels

| Level | Description | Use Case |
|-------|-------------|----------|
| **L1 - Module** | Individual module debugging | Unit testing, function verification |
| **L2 - Integration** | Inter-module debugging | Interface verification, signal integrity |
| **L3 - System** | Full system debugging | End-to-end functionality, performance |
| **L4 - Application** | Software debugging | Algorithm verification, optimization |

## 2. Debug Environment Setup

### 2.1 Required Tools

#### Simulation Tools
```bash
# Essential simulation tools
sudo apt-get install verilator gtkwave
pip3 install cocotb pytest

# Optional advanced tools
# - Questa/ModelSim for advanced debugging
# - Synopsys VCS for formal verification
# - Cadence Xcelium for mixed-signal simulation
```

#### Analysis Tools
```bash
# Performance analysis
pip3 install numpy matplotlib pandas

# RTL analysis
pip3 install fusesoc edalize

# Debug utilities
sudo apt-get install gdb valgrind
```

### 2.2 Environment Configuration

#### Debug Build Configuration
```bash
# Set debug environment variables
export MHX_DEBUG_LEVEL=3           # Maximum debug verbosity
export MHX_TRACE_ENABLE=1          # Enable operation tracing
export MHX_ASSERT_ENABLE=1         # Enable assertions
export MHX_COVERAGE_ENABLE=1       # Enable coverage collection

# Simulator configuration
export VERILATOR_ROOT=/usr/share/verilator
export GTK_WAVE_VIEWER=gtkwave
```

#### Debug Compilation Flags
```bash
# Verilator debug flags
VFLAGS="--debug --trace --coverage --assert"

# Synthesis debug flags (for FPGA)
SYNTH_FLAGS="-debug_level 3 -keep_hierarchy -preserve_signal"
```

### 2.3 Project Structure for Debugging

```
debug/
├── waveforms/          # Generated waveform files
├── coverage/          # Coverage reports
├── logs/             # Debug and simulation logs
├── traces/           # Execution traces
├── scripts/          # Debug automation scripts
└── testbenches/      # Debug-specific testbenches
```

## 3. Ternary ALU Debugging

### 3.1 ALU Debug Signals

#### Debug Signal Definitions
```systemverilog
// Add these signals to ibex_ternary_alu.sv for debugging
module ibex_ternary_alu_debug import ibex_pkg::*; (
  // ... existing ports ...

  // Debug outputs
  output logic [15:0][1:0] debug_trit_a,        // Individual input trits A
  output logic [15:0][1:0] debug_trit_b,        // Individual input trits B
  output logic [15:0][1:0] debug_trit_result,   // Individual result trits
  output logic [15:0]      debug_trit_valid,    // Trit validity flags
  output logic [6:0]       debug_operation,     // Current operation
  output logic [31:0]      debug_cycle_count    // Operation cycle counter
);

// Debug signal assignments
genvar debug_i;
generate
  for (debug_i = 0; debug_i < 16; debug_i++) begin
    assign debug_trit_a[debug_i]      = operand_a_i[debug_i*2 +: 2];
    assign debug_trit_b[debug_i]      = operand_b_i[debug_i*2 +: 2];
    assign debug_trit_result[debug_i] = result_o[debug_i*2 +: 2];
    assign debug_trit_valid[debug_i]  = is_valid_trit(debug_trit_result[debug_i]);
  end
endgenerate

assign debug_operation = {4'b0, operator_i};
```

#### Debug Testbench
```systemverilog
// debug_ternary_alu_tb.sv
module debug_ternary_alu_tb;
  // Testbench signals
  logic [31:0] operand_a, operand_b, result;
  ternary_op_e operator;
  logic ready, overflow;
  logic [15:0] trit_overflow;

  // Debug monitoring
  logic [15:0][1:0] debug_trit_a, debug_trit_b, debug_trit_result;
  logic [15:0] debug_trit_valid;

  // DUT instantiation
  ibex_ternary_alu #(
    .TernaryDataWidth(32),
    .NumTrits(16)
  ) dut (.*);

  // Test stimulus
  initial begin
    $display("=== MHX Ternary ALU Debug Test ===");

    // Test each operation systematically
    test_operation(TERNARY_ADD, "Addition");
    test_operation(TERNARY_SUB, "Subtraction");
    test_operation(TERNARY_MUL, "Multiplication");
    test_operation(TERNARY_AND, "AND");
    test_operation(TERNARY_OR, "OR");
    test_operation(TERNARY_XOR, "XOR");
    test_operation(TERNARY_NOT, "NOT");

    $display("=== Debug Test Complete ===");
    $finish;
  end

  // Operation test task
  task test_operation(ternary_op_e op, string op_name);
    $display("\n--- Testing %s Operation ---", op_name);
    operator = op;

    // Test corner cases
    test_corner_cases(op);

    // Test random cases
    repeat(100) test_random_case(op);

    // Check for any invalid results
    check_result_validity();
  endtask

  // Corner case testing
  task test_corner_cases(ternary_op_e op);
    // All zeros
    operand_a = 32'h55555555; // All TRIT_ZERO
    operand_b = 32'h55555555;
    #1;
    $display("All zeros: A=%h, B=%h, R=%h", operand_a, operand_b, result);

    // All positive
    operand_a = 32'hAAAAAAAA; // All TRIT_POS
    operand_b = 32'hAAAAAAAA;
    #1;
    $display("All positive: A=%h, B=%h, R=%h, OV=%b", operand_a, operand_b, result, overflow);

    // All negative
    operand_a = 32'h00000000; // All TRIT_NEG
    operand_b = 32'h00000000;
    #1;
    $display("All negative: A=%h, B=%h, R=%h, OV=%b", operand_a, operand_b, result, overflow);

    // Mixed patterns
    operand_a = 32'h50A050A0; // Alternating pattern
    operand_b = 32'hA050A050;
    #1;
    $display("Mixed pattern: A=%h, B=%h, R=%h", operand_a, operand_b, result);
  endtask

  // Random case testing
  task test_random_case(ternary_op_e op);
    operand_a = generate_random_ternary();
    operand_b = generate_random_ternary();
    #1;

    // Log if interesting result detected
    if (overflow || !(&debug_trit_valid)) begin
      $display("Random case: A=%h, B=%h, R=%h, OV=%b, Valid=%b",
               operand_a, operand_b, result, overflow, &debug_trit_valid);
    end
  endtask

  // Generate random valid ternary data
  function logic [31:0] generate_random_ternary();
    logic [31:0] data;
    for (int i = 0; i < 16; i++) begin
      case ($urandom % 3)
        0: data[i*2 +: 2] = TRIT_NEG;
        1: data[i*2 +: 2] = TRIT_ZERO;
        2: data[i*2 +: 2] = TRIT_POS;
      endcase
    end
    return data;
  endfunction

  // Result validity checker
  task check_result_validity();
    if (!(&debug_trit_valid)) begin
      $error("Invalid trits detected in result!");
      for (int i = 0; i < 16; i++) begin
        if (!debug_trit_valid[i]) begin
          $error("  Trit[%0d]: %b (invalid)", i, debug_trit_result[i]);
        end
      end
    end else begin
      $display("✅ All result trits are valid");
    end
  endtask

  // Waveform generation
  initial begin
    $dumpfile("debug_ternary_alu.vcd");
    $dumpvars(0, debug_ternary_alu_tb);
  end

endmodule
```

### 3.2 Common ALU Issues and Solutions

#### Issue: Invalid Trit Outputs
**Symptoms:** Result contains `2'b11` encodings
**Debug Steps:**
```systemverilog
// Add assertion to catch invalid outputs
always_comb begin
  for (int i = 0; i < 16; i++) begin
    assert(result_o[i*2 +: 2] inside {TRIT_NEG, TRIT_ZERO, TRIT_POS})
      else $error("Invalid trit at position %d: %b", i, result_o[i*2 +: 2]);
  end
end
```
**Solution:** Check function truth tables and default cases

#### Issue: Overflow Flags Not Set
**Symptoms:** Expected overflow not detected
**Debug Steps:**
```systemverilog
// Add overflow monitoring
always_comb begin
  if (operator_i == TERNARY_ADD) begin
    for (int i = 0; i < 16; i++) begin
      logic [1:0] ta = operand_a_i[i*2 +: 2];
      logic [1:0] tb = operand_b_i[i*2 +: 2];

      // Manually check overflow conditions
      if ((ta == TRIT_NEG && tb == TRIT_NEG) ||
          (ta == TRIT_POS && tb == TRIT_POS)) begin
        assert(trit_overflow_o[i])
          else $error("Missing overflow at trit %d: %b + %b", i, ta, tb);
      end
    end
  end
end
```

#### Issue: Timing Violations
**Symptoms:** Setup/hold violations in simulation
**Debug Steps:**
1. Check combinational logic depth
2. Verify clock constraints
3. Add pipeline stages if needed

## 4. Neural Unit Debugging

### 4.1 Neural Debug Signals

```systemverilog
// Add to ibex_neural_unit.sv
module ibex_neural_unit_debug import ibex_pkg::*; (
  // ... existing ports ...

  // Debug outputs
  output logic signed [7:0]    debug_accumulator,     // Current accumulator value
  output logic signed [15:0][1:0] debug_weights,      // Individual weight trits
  output logic signed [15:0][1:0] debug_inputs,       // Individual input trits
  output logic signed [15:0][3:0] debug_products,     // Individual products
  output logic [1:0]           debug_bias_trit,       // Extracted bias
  output logic [3:0]           debug_operation_stage, // Operation pipeline stage
  output logic                 debug_bounds_ok        // Accumulator in bounds
);

// Debug assignments
assign debug_accumulator = next_accumulator;
assign debug_bias_trit = bias_i[1:0];
assign debug_bounds_ok = (next_accumulator >= -17 && next_accumulator <= 17);

genvar debug_j;
generate
  for (debug_j = 0; debug_j < 16; debug_j++) begin
    assign debug_weights[debug_j] = weights_i[debug_j*2 +: 2];
    assign debug_inputs[debug_j]  = inputs_i[debug_j*2 +: 2];

    // Calculate individual products for debugging
    always_comb begin
      logic signed [1:0] w_int = trit_to_int(debug_weights[debug_j]);
      logic signed [1:0] i_int = trit_to_int(debug_inputs[debug_j]);
      debug_products[debug_j] = w_int * i_int;
    end
  end
endgenerate
```

### 4.2 Neural Unit Test Scenarios

#### Testbench for Neural Debugging
```systemverilog
module debug_neural_unit_tb;
  // Signals
  logic [31:0] weights, inputs, bias, result;
  neural_op_e operation;
  logic valid;

  // Debug signals
  logic signed [7:0] debug_accumulator;
  logic signed [15:0][1:0] debug_weights, debug_inputs;
  logic signed [15:0][3:0] debug_products;
  logic debug_bounds_ok;

  // DUT
  ibex_neural_unit #(
    .TernaryDataWidth(32),
    .NumTrits(16)
  ) dut (.*);

  initial begin
    $display("=== Neural Unit Debug Test ===");

    // Test 1: Simple multiply-accumulate
    test_simple_mac();

    // Test 2: Boundary conditions
    test_boundary_conditions();

    // Test 3: All neural operations
    test_all_operations();

    $finish;
  end

  task test_simple_mac();
    $display("\n--- Simple MAC Test ---");

    // Set up simple pattern: weights=1, inputs=1, bias=0
    weights = 32'hAAAAAAAA;  // All +1
    inputs  = 32'h55555555;  // All 0
    bias    = 32'h00000001;  // bias = 0
    operation = NEURAL_MULTIPLY;

    #1;
    $display("Weights all +1, Inputs all 0:");
    $display("  Accumulator: %d (expected: 0)", debug_accumulator);
    $display("  Result: %h", result);

    // Change inputs to +1
    inputs = 32'hAAAAAAAA;   // All +1
    #1;
    $display("Weights all +1, Inputs all +1:");
    $display("  Accumulator: %d (expected: 16)", debug_accumulator);
    $display("  Result: %h", result);

    // Mixed pattern
    weights = 32'h50A050A0;  // Alternating -1, 0, +1, 0, ...
    inputs  = 32'hA050A050;  // Alternating +1, 0, -1, 0, ...
    #1;
    $display("Mixed pattern:");
    $display("  Accumulator: %d", debug_accumulator);

    // Print individual products for analysis
    for (int i = 0; i < 16; i++) begin
      if (debug_products[i] != 0) begin
        $display("  Product[%2d]: %d", i, debug_products[i]);
      end
    end
  endtask

  task test_boundary_conditions();
    $display("\n--- Boundary Condition Test ---");

    // Maximum positive accumulation
    weights = 32'hAAAAAAAA;  // All +1
    inputs  = 32'hAAAAAAAA;  // All +1
    bias    = 32'h00000002;  // bias = +1
    operation = NEURAL_MULTIPLY;

    #1;
    $display("Maximum positive: Accumulator=%d, Bounds OK=%b",
             debug_accumulator, debug_bounds_ok);

    // Maximum negative accumulation
    weights = 32'h00000000;  // All -1
    inputs  = 32'hAAAAAAAA;  // All +1 (creates all -1 products)
    bias    = 32'h00000000;  // bias = -1

    #1;
    $display("Maximum negative: Accumulator=%d, Bounds OK=%b",
             debug_accumulator, debug_bounds_ok);

    // Test accumulator bounds assertion
    if (!debug_bounds_ok) begin
      $error("Accumulator out of bounds: %d", debug_accumulator);
    end
  endtask

  task test_all_operations();
    $display("\n--- All Operations Test ---");

    // Set up test data
    weights = 32'h50A050A0;
    inputs  = 32'hA050A050;
    bias    = 32'h00000001;  // bias = 0

    // Test each operation
    operation = NEURAL_MULTIPLY;
    #1;
    $display("NEURAL_MULTIPLY: Result=%h, Valid=%b", result, valid);

    operation = NEURAL_ACCUMULATE;
    #1;
    $display("NEURAL_ACCUMULATE: Result=%h, Valid=%b", result, valid);

    operation = NEURAL_ACTIVATE;
    #1;
    $display("NEURAL_ACTIVATE: Result=%h, Valid=%b", result, valid);
    $display("  Activation result trit: %b", result[1:0]);

    operation = NEURAL_LEARN;
    #1;
    $display("NEURAL_LEARN: Result=%h, Valid=%b", result, valid);
  endtask

  // Continuous monitoring
  always @(posedge operation) begin
    $display("Operation changed to: %s", operation.name());
  end

  // Waveform dump
  initial begin
    $dumpfile("debug_neural_unit.vcd");
    $dumpvars(0, debug_neural_unit_tb);
  end

endmodule
```

### 4.3 Neural Unit Debug Checklist

#### Accumulator Debugging
- [ ] Verify accumulator range (-17 to +17)
- [ ] Check individual weight×input products
- [ ] Validate bias addition
- [ ] Monitor overflow/underflow conditions

#### Operation Debugging
- [ ] Verify NEURAL_MULTIPLY produces raw accumulator
- [ ] Check NEURAL_ACCUMULATE behavior
- [ ] Validate NEURAL_ACTIVATE thresholding
- [ ] Confirm NEURAL_LEARN pass-through

#### Performance Debugging
- [ ] Measure operation latency
- [ ] Check combinational timing
- [ ] Validate pipeline behavior (if added)

## 5. Register File Debugging

### 5.1 Register File Debug Monitoring

```systemverilog
// Add to ibex_ternary_regfile.sv for debugging
module debug_ternary_regfile_wrapper;
  // ... existing signals ...

  // Debug monitoring
  logic [15:0][31:0] debug_reg_contents;  // All register contents
  logic [15:0][7:0]  debug_reg_parity;    // Parity for each register
  logic [15:0]       debug_reg_valid;     // Validity flags
  logic [31:0]       debug_last_write;    // Last written data
  logic [3:0]        debug_last_addr;     // Last written address

  // Register file instance with debug wrapper
  ibex_ternary_regfile regfile_inst (.*);

  // Debug assignments
  assign debug_reg_contents = regfile_inst.ternary_regs;

  genvar debug_k;
  generate
    for (debug_k = 0; debug_k < 16; debug_k++) begin
      assign debug_reg_parity[debug_k] = ^debug_reg_contents[debug_k];
      assign debug_reg_valid[debug_k] = all_trits_valid(debug_reg_contents[debug_k]);
    end
  endgenerate

  // Write monitoring
  always_ff @(posedge clk_i) begin
    if (we_i) begin
      debug_last_write <= wdata_i;
      debug_last_addr  <= waddr_i;
    end
  end

  // Debug tasks
  task print_all_registers();
    $display("\n=== Register File Contents ===");
    for (int i = 0; i < 16; i++) begin
      $display("T%-2d: %h (valid=%b, parity=%h)",
               i, debug_reg_contents[i], debug_reg_valid[i], debug_reg_parity[i]);
    end
    $display("==============================");
  endtask

  task check_register_integrity();
    logic integrity_ok = 1'b1;
    for (int i = 0; i < 16; i++) begin
      if (!debug_reg_valid[i]) begin
        $error("Register T%0d contains invalid trits: %h", i, debug_reg_contents[i]);
        integrity_ok = 1'b0;
      end
    end
    if (integrity_ok) begin
      $display("✅ All registers contain valid ternary data");
    end
  endtask

endmodule
```

### 5.2 Register File Test Patterns

```systemverilog
module debug_regfile_tb;
  // Standard signals
  logic clk_i, rst_ni, we_i;
  logic [3:0] raddr_a_i, raddr_b_i, waddr_i;
  logic [31:0] rdata_a_o, rdata_b_o, wdata_i;

  // Clock generation
  initial clk_i = 0;
  always #5 clk_i = ~clk_i;

  // DUT instantiation
  debug_ternary_regfile_wrapper dut (.*);

  initial begin
    $display("=== Register File Debug Test ===");

    // Reset sequence
    rst_ni = 0;
    we_i = 0;
    #20;
    rst_ni = 1;
    #10;

    // Test basic write/read
    test_basic_write_read();

    // Test simultaneous read/write
    test_simultaneous_access();

    // Test all registers
    test_all_registers();

    // Check data integrity
    dut.check_register_integrity();
    dut.print_all_registers();

    $finish;
  end

  task test_basic_write_read();
    $display("\n--- Basic Write/Read Test ---");

    // Write to register T5
    @(posedge clk_i);
    waddr_i = 4'd5;
    wdata_i = 32'h50A050A0;  // Test pattern
    we_i = 1;

    @(posedge clk_i);
    we_i = 0;

    // Read from register T5
    raddr_a_i = 4'd5;
    raddr_b_i = 4'd5;

    @(posedge clk_i);
    #1;  // Combinational delay

    $display("Wrote %h to T5, read A=%h, B=%h", 32'h50A050A0, rdata_a_o, rdata_b_o);

    if (rdata_a_o != 32'h50A050A0 || rdata_b_o != 32'h50A050A0) begin
      $error("Read mismatch!");
    end else begin
      $display("✅ Basic write/read successful");
    end
  endtask

  task test_simultaneous_access();
    $display("\n--- Simultaneous Access Test ---");

    // Write to T3 while reading from T1 and T2
    @(posedge clk_i);
    waddr_i = 4'd3;
    wdata_i = 32'hAAAAAAAA;  // All +1
    we_i = 1;
    raddr_a_i = 4'd1;
    raddr_b_i = 4'd2;

    @(posedge clk_i);
    we_i = 0;
    #1;

    $display("Simultaneous: Write T3=%h, Read T1=%h, T2=%h",
             32'hAAAAAAAA, rdata_a_o, rdata_b_o);
  endtask

  task test_all_registers();
    $display("\n--- All Registers Test ---");

    // Write unique pattern to each register
    for (int i = 0; i < 16; i++) begin
      @(posedge clk_i);
      waddr_i = i[3:0];
      wdata_i = generate_test_pattern(i);
      we_i = 1;
    end

    @(posedge clk_i);
    we_i = 0;

    // Verify each register
    for (int i = 0; i < 16; i++) begin
      raddr_a_i = i[3:0];
      #1;
      logic [31:0] expected = generate_test_pattern(i);
      if (rdata_a_o != expected) begin
        $error("Register T%0d mismatch: got %h, expected %h", i, rdata_a_o, expected);
      end else begin
        $display("T%-2d: %h ✅", i, rdata_a_o);
      end
    end
  endtask

  function logic [31:0] generate_test_pattern(int reg_num);
    // Generate unique ternary pattern for each register
    logic [31:0] pattern;
    for (int j = 0; j < 16; j++) begin
      case ((reg_num + j) % 3)
        0: pattern[j*2 +: 2] = TRIT_NEG;
        1: pattern[j*2 +: 2] = TRIT_ZERO;
        2: pattern[j*2 +: 2] = TRIT_POS;
      endcase
    end
    return pattern;
  endfunction

  // Waveforms
  initial begin
    $dumpfile("debug_regfile.vcd");
    $dumpvars(0, debug_regfile_tb);
  end

endmodule
```

## 6. Integration Debugging

### 6.1 Core Integration Debug Points

```systemverilog
// Add to ibex_core.sv for integration debugging
module ibex_core_debug_wrapper import ibex_pkg::*; (
  // ... existing ports ...

  // Debug outputs
  output logic        debug_ternary_instruction,    // Ternary instruction detected
  output logic        debug_neural_instruction,     // Neural instruction detected
  output ternary_op_e debug_ternary_operation,      // Current ternary op
  output neural_op_e  debug_neural_operation,       // Current neural op
  output logic [3:0]  debug_ternary_raddr_a,        // Ternary read address A
  output logic [3:0]  debug_ternary_raddr_b,        // Ternary read address B
  output logic [3:0]  debug_ternary_waddr,          // Ternary write address
  output logic [31:0] debug_ternary_rdata_a,        // Ternary read data A
  output logic [31:0] debug_ternary_rdata_b,        // Ternary read data B
  output logic [31:0] debug_ternary_wdata,          // Ternary write data
  output logic        debug_ternary_we,             // Ternary write enable
  output logic        debug_alu_ready,              // ALU ready flag
  output logic        debug_alu_overflow,           // ALU overflow flag
  output logic        debug_neural_valid            // Neural unit valid flag
);

// Core instance
ibex_core core_inst (.*);

// Debug assignments
assign debug_ternary_instruction = core_inst.ternary_en_id;
assign debug_neural_instruction = core_inst.neural_en_id;
assign debug_ternary_operation = core_inst.ternary_op_id;
assign debug_neural_operation = core_inst.neural_op_id;
assign debug_ternary_raddr_a = core_inst.ternary_raddr_a_id;
assign debug_ternary_raddr_b = core_inst.ternary_raddr_b_id;
assign debug_ternary_waddr = core_inst.ternary_waddr_id;
assign debug_ternary_rdata_a = core_inst.ternary_rdata_a;
assign debug_ternary_rdata_b = core_inst.ternary_rdata_b;
assign debug_ternary_wdata = core_inst.ternary_wdata;
assign debug_ternary_we = core_inst.ternary_we_wb;
assign debug_alu_ready = core_inst.ternary_alu_ready;
assign debug_alu_overflow = core_inst.ternary_alu_overflow;
assign debug_neural_valid = core_inst.neural_valid;

// Debug monitoring tasks
task monitor_ternary_execution();
  $display("\n=== Ternary Execution Monitor ===");
  $display("Ternary Instr: %b", debug_ternary_instruction);
  $display("Neural Instr:  %b", debug_neural_instruction);

  if (debug_ternary_instruction) begin
    $display("Ternary Op:    %s", debug_ternary_operation.name());
    $display("Read Addrs:    A=T%0d, B=T%0d", debug_ternary_raddr_a, debug_ternary_raddr_b);
    $display("Write Addr:    T%0d", debug_ternary_waddr);
    $display("Read Data:     A=%h, B=%h", debug_ternary_rdata_a, debug_ternary_rdata_b);
    $display("Write Data:    %h", debug_ternary_wdata);
    $display("Write Enable:  %b", debug_ternary_we);
    $display("ALU Ready:     %b", debug_alu_ready);
    $display("ALU Overflow:  %b", debug_alu_overflow);
  end

  if (debug_neural_instruction) begin
    $display("Neural Op:     %s", debug_neural_operation.name());
    $display("Neural Valid:  %b", debug_neural_valid);
  end
  $display("=================================");
endtask

endmodule
```

### 6.2 Instruction Trace Debug

```systemverilog
// Instruction execution tracer
module ternary_instruction_tracer;
  // Inputs from core
  logic        clk_i;
  logic        instr_valid_id;
  logic [31:0] instr_rdata_id;
  logic [31:0] pc_id;
  logic        ternary_en_id;
  logic        neural_en_id;
  ternary_op_e ternary_op_id;
  neural_op_e  neural_op_id;

  // Trace file
  integer trace_file;

  initial begin
    trace_file = $fopen("ternary_execution_trace.log", "w");
    $fdisplay(trace_file, "=== MHX Ternary Execution Trace ===");
    $fdisplay(trace_file, "Timestamp,PC,Instruction,Type,Operation,Details");
  end

  // Trace ternary instructions
  always_ff @(posedge clk_i) begin
    if (instr_valid_id && (ternary_en_id || neural_en_id)) begin
      string instr_type = ternary_en_id ? "TERNARY" : "NEURAL";
      string operation = ternary_en_id ? ternary_op_id.name() : neural_op_id.name();

      $fdisplay(trace_file, "%0t,%08h,%08h,%s,%s,rA=%0d,rB=%0d,wD=%0d",
                $time, pc_id, instr_rdata_id, instr_type, operation,
                instr_rdata_id[19:16], instr_rdata_id[23:20], instr_rdata_id[11:8]);

      $display("[TRACE] %0t: %s %s @ PC=%08h",
               $time, instr_type, operation, pc_id);
    end
  end

  final begin
    $fclose(trace_file);
    $display("Execution trace saved to ternary_execution_trace.log");
  end

endmodule
```

## 7. Common Issues and Solutions

### 7.1 Decoder Integration Issues

#### Issue: Ternary Instructions Not Recognized
**Symptoms:**
- Illegal instruction exceptions for ternary opcodes
- `ternary_en_id` never asserts

**Debug Steps:**
```systemverilog
// Add to decoder debug
always_ff @(posedge clk_i) begin
  if (instr_valid_i) begin
    logic [6:0] opcode = instr_rdata_i[6:0];
    if (opcode == OPCODE_TERNARY) begin
      $display("TERNARY opcode detected: %07b", opcode);
      assert(ternary_en_o) else $error("ternary_en_o not asserted!");
    end
  end
end
```

**Solutions:**
1. Verify `OPCODE_TERNARY` and `OPCODE_NEURAL` definitions in `ibex_pkg.sv`
2. Check decoder case statement includes both opcodes
3. Ensure `ternary_en_o` is properly connected

#### Issue: Invalid `funct3` Fields
**Symptoms:**
- Valid ternary opcodes but wrong operations executed

**Debug Steps:**
```systemverilog
// Monitor funct3 decoding
always_comb begin
  if (ternary_en_o) begin
    logic [2:0] funct3 = instr_rdata_i[14:12];
    $display("Ternary funct3: %03b -> %s", funct3, ternary_op_o.name());
  end
end
```

### 7.2 Signal Connection Issues

#### Issue: Ternary Signals Not Connected
**Symptoms:**
- Modules instantiated but no functional behavior
- Simulation warnings about unconnected signals

**Debug Checklist:**
- [ ] ID stage outputs connected to core signals
- [ ] Core signals connected to ternary modules
- [ ] Ternary register file properly instantiated
- [ ] Clock and reset signals propagated

#### Issue: Signal Width Mismatches
**Symptoms:**
- Compilation errors about port width mismatches
- Truncated or padded signal values

**Solutions:**
1. Use parameters consistently across modules
2. Check `TernaryDataWidth` and `NumTrits` parameters
3. Verify address width matches register count

### 7.3 Timing and Performance Issues

#### Issue: Long Combinational Paths
**Symptoms:**
- Timing violations in synthesis
- Slow simulation performance

**Analysis:**
```bash
# Use Verilator timing analysis
verilator --timing-analysis --top-module ibex_core rtl/*.sv

# Check critical path report
grep -A 10 "Critical Path" timing_report.txt
```

**Solutions:**
1. Add pipeline registers to ternary ALU
2. Optimize neural unit accumulator loop
3. Use faster adder implementations

## 8. Performance Analysis

### 8.1 Cycle-Level Performance Debugging

```systemverilog
// Performance counter module
module ternary_performance_counters (
  input logic clk_i,
  input logic rst_ni,

  // Events to count
  input logic ternary_instruction_i,
  input logic neural_instruction_i,
  input logic ternary_alu_ready_i,
  input logic neural_unit_valid_i,
  input logic ternary_overflow_i,

  // Counters
  output logic [31:0] total_cycles_o,
  output logic [31:0] ternary_instructions_o,
  output logic [31:0] neural_instructions_o,
  output logic [31:0] alu_operations_o,
  output logic [31:0] neural_operations_o,
  output logic [31:0] overflow_events_o
);

// Counter implementations
always_ff @(posedge clk_i or negedge rst_ni) begin
  if (!rst_ni) begin
    total_cycles_o <= '0;
    ternary_instructions_o <= '0;
    neural_instructions_o <= '0;
    alu_operations_o <= '0;
    neural_operations_o <= '0;
    overflow_events_o <= '0;
  end else begin
    total_cycles_o <= total_cycles_o + 1'b1;

    if (ternary_instruction_i) ternary_instructions_o <= ternary_instructions_o + 1'b1;
    if (neural_instruction_i)  neural_instructions_o  <= neural_instructions_o + 1'b1;
    if (ternary_alu_ready_i)   alu_operations_o       <= alu_operations_o + 1'b1;
    if (neural_unit_valid_i)   neural_operations_o    <= neural_operations_o + 1'b1;
    if (ternary_overflow_i)    overflow_events_o      <= overflow_events_o + 1'b1;
  end
end

endmodule
```

### 8.2 Performance Analysis Scripts

```python
#!/usr/bin/env python3
# performance_analyzer.py

import re
import matplotlib.pyplot as plt
import numpy as np
from pathlib import Path

class TernaryPerformanceAnalyzer:
    def __init__(self, trace_file="ternary_execution_trace.log"):
        self.trace_file = trace_file
        self.instructions = []
        self.timestamps = []

    def parse_trace(self):
        """Parse execution trace file"""
        with open(self.trace_file, 'r') as f:
            for line in f:
                if line.startswith("Timestamp"):
                    continue  # Skip header

                parts = line.strip().split(',')
                if len(parts) >= 5:
                    timestamp = int(parts[0])
                    instr_type = parts[3]
                    operation = parts[4]

                    self.timestamps.append(timestamp)
                    self.instructions.append((instr_type, operation))

    def analyze_performance(self):
        """Analyze performance metrics"""
        if not self.instructions:
            print("No instruction data found")
            return

        total_instructions = len(self.instructions)
        ternary_count = sum(1 for instr in self.instructions if instr[0] == 'TERNARY')
        neural_count = sum(1 for instr in self.instructions if instr[0] == 'NEURAL')

        if len(self.timestamps) > 1:
            total_cycles = self.timestamps[-1] - self.timestamps[0]
            ipc = total_instructions / total_cycles if total_cycles > 0 else 0
        else:
            total_cycles = 0
            ipc = 0

        print(f"=== Performance Analysis ===")
        print(f"Total Instructions: {total_instructions}")
        print(f"Ternary Instructions: {ternary_count} ({ternary_count/total_instructions*100:.1f}%)")
        print(f"Neural Instructions: {neural_count} ({neural_count/total_instructions*100:.1f}%)")
        print(f"Total Cycles: {total_cycles}")
        print(f"Instructions per Cycle: {ipc:.3f}")

        # Operation frequency analysis
        op_counts = {}
        for _, op in self.instructions:
            op_counts[op] = op_counts.get(op, 0) + 1

        print(f"\nOperation Frequency:")
        for op, count in sorted(op_counts.items(), key=lambda x: x[1], reverse=True):
            print(f"  {op}: {count} ({count/total_instructions*100:.1f}%)")

    def plot_instruction_timeline(self):
        """Plot instruction execution timeline"""
        if not self.timestamps:
            return

        fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(12, 8))

        # Instruction types over time
        ternary_times = [t for i, t in enumerate(self.timestamps)
                        if self.instructions[i][0] == 'TERNARY']
        neural_times = [t for i, t in enumerate(self.timestamps)
                       if self.instructions[i][0] == 'NEURAL']

        ax1.scatter(ternary_times, [1]*len(ternary_times),
                   label='Ternary', alpha=0.7, s=20)
        ax1.scatter(neural_times, [2]*len(neural_times),
                   label='Neural', alpha=0.7, s=20)
        ax1.set_ylabel('Instruction Type')
        ax1.set_yticks([1, 2])
        ax1.set_yticklabels(['Ternary', 'Neural'])
        ax1.legend()
        ax1.grid(True, alpha=0.3)

        # Instruction frequency over time (sliding window)
        window_size = max(len(self.timestamps) // 20, 1)
        windowed_times = []
        windowed_freq = []

        for i in range(0, len(self.timestamps) - window_size, window_size//2):
            window_start = self.timestamps[i]
            window_end = self.timestamps[min(i + window_size, len(self.timestamps)-1)]
            freq = window_size / (window_end - window_start) if window_end > window_start else 0

            windowed_times.append((window_start + window_end) / 2)
            windowed_freq.append(freq)

        ax2.plot(windowed_times, windowed_freq, 'b-', linewidth=2)
        ax2.set_xlabel('Time (cycles)')
        ax2.set_ylabel('Instructions per Cycle')
        ax2.grid(True, alpha=0.3)

        plt.tight_layout()
        plt.savefig('ternary_performance_timeline.png', dpi=300, bbox_inches='tight')
        print("Timeline plot saved to ternary_performance_timeline.png")

if __name__ == "__main__":
    analyzer = TernaryPerformanceAnalyzer()
    analyzer.parse_trace()
    analyzer.analyze_performance()
    analyzer.plot_instruction_timeline()
```

## 9. Simulation and Testing

### 9.1 Automated Test Suite

```bash
#!/bin/bash
# run_debug_tests.sh

set -e

WORKSPACE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${WORKSPACE_ROOT}/build/debug"
RESULTS_DIR="${BUILD_DIR}/results"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Setup
mkdir -p "${BUILD_DIR}" "${RESULTS_DIR}"
cd "${BUILD_DIR}"

log_info "Starting MHX Ternary Debug Test Suite..."

# Test 1: Ternary ALU
log_info "Running Ternary ALU debug tests..."
verilator --cc --exe --build -Wall \
  -I "${WORKSPACE_ROOT}/rtl" \
  "${WORKSPACE_ROOT}/rtl/ibex_pkg.sv" \
  "${WORKSPACE_ROOT}/rtl/ibex_ternary_alu.sv" \
  "${WORKSPACE_ROOT}/debug/testbenches/debug_ternary_alu_tb.sv" \
  --top-module debug_ternary_alu_tb

./Vdebug_ternary_alu_tb > "${RESULTS_DIR}/alu_test.log" 2>&1
if [[ $? -eq 0 ]]; then
  log_info "✅ Ternary ALU tests passed"
else
  log_error "❌ Ternary ALU tests failed"
  cat "${RESULTS_DIR}/alu_test.log"
  exit 1
fi

# Test 2: Neural Unit
log_info "Running Neural Unit debug tests..."
verilator --cc --exe --build -Wall \
  -I "${WORKSPACE_ROOT}/rtl" \
  "${WORKSPACE_ROOT}/rtl/ibex_pkg.sv" \
  "${WORKSPACE_ROOT}/rtl/ibex_neural_unit.sv" \
  "${WORKSPACE_ROOT}/debug/testbenches/debug_neural_unit_tb.sv" \
  --top-module debug_neural_unit_tb

./Vdebug_neural_unit_tb > "${RESULTS_DIR}/neural_test.log" 2>&1
if [[ $? -eq 0 ]]; then
  log_info "✅ Neural Unit tests passed"
else
  log_error "❌ Neural Unit tests failed"
  cat "${RESULTS_DIR}/neural_test.log"
  exit 1
fi

# Test 3: Register File
log_info "Running Register File debug tests..."
verilator --cc --exe --build -Wall \
  -I "${WORKSPACE_ROOT}/rtl" \
  "${WORKSPACE_ROOT}/rtl/ibex_pkg.sv" \
  "${WORKSPACE_ROOT}/rtl/ibex_ternary_regfile.sv" \
  "${WORKSPACE_ROOT}/debug/testbenches/debug_regfile_tb.sv" \
  --top-module debug_regfile_tb

./Vdebug_regfile_tb > "${RESULTS_DIR}/regfile_test.log" 2>&1
if [[ $? -eq 0 ]]; then
  log_info "✅ Register File tests passed"
else
  log_error "❌ Register File tests failed"
  cat "${RESULTS_DIR}/regfile_test.log"
  exit 1
fi

# Performance Analysis
log_info "Running performance analysis..."
if [[ -f "${RESULTS_DIR}/ternary_execution_trace.log" ]]; then
  python3 "${WORKSPACE_ROOT}/debug/scripts/performance_analyzer.py"
else
  log_warn "No execution trace found for performance analysis"
fi

# Generate final report
log_info "Generating debug test report..."
cat > "${RESULTS_DIR}/debug_test_report.md" << EOF
# MHX Ternary Debug Test Report

**Date:** $(date)
**Build:** ${BUILD_DIR}

## Test Results
- ✅ Ternary ALU: All tests passed
- ✅ Neural Unit: All tests passed
- ✅ Register File: All tests passed

## Files Generated
- \`alu_test.log\`: Ternary ALU test output
- \`neural_test.log\`: Neural Unit test output
- \`regfile_test.log\`: Register File test output
- \`*.vcd\`: Waveform files for analysis

## Recommendations
1. Review waveforms with GTKWave: \`gtkwave debug_*.vcd\`
2. Check performance metrics in analysis plots
3. Verify all assertions passed in test logs

**Overall Status:** ✅ ALL DEBUG TESTS PASSED

EOF

log_info "✅ All debug tests completed successfully!"
log_info "Results saved in: ${RESULTS_DIR}"
log_info "View report: ${RESULTS_DIR}/debug_test_report.md"
```

## 10. Hardware Debug

### 10.1 FPGA Debug Setup

For hardware debugging on FPGA platforms:

#### ChipScope/ILA Integration
```systemverilog
// Add Integrated Logic Analyzer (ILA) for hardware debug
module ternary_ila_wrapper (
  input logic clk_i,

  // Ternary signals to probe
  input logic        ternary_en_id,
  input logic        neural_en_id,
  input ternary_op_e ternary_op_id,
  input logic [31:0] ternary_rdata_a,
  input logic [31:0] ternary_rdata_b,
  input logic [31:0] ternary_alu_result,
  input logic        ternary_alu_overflow
);

// Xilinx ILA instance (adjust for your FPGA vendor)
`ifdef XILINX_FPGA
ila_0 ternary_ila_inst (
  .clk(clk_i),
  .probe0(ternary_en_id),
  .probe1(neural_en_id),
  .probe2(ternary_op_id),
  .probe3(ternary_rdata_a),
  .probe4(ternary_rdata_b),
  .probe5(ternary_alu_result),
  .probe6(ternary_alu_overflow)
);
`endif

endmodule
```

#### Hardware Debug Checklist
- [ ] Clock domains properly connected
- [ ] Reset sequences working correctly
- [ ] Ternary register initialization verified
- [ ] Instruction decode functioning in hardware
- [ ] Performance counters accessible
- [ ] Temperature and power within limits

### 10.2 Debug Interface

```systemverilog
// JTAG debug interface for ternary extensions
module ternary_debug_interface (
  // JTAG signals
  input  logic jtag_tck_i,
  input  logic jtag_tms_i,
  input  logic jtag_tdi_i,
  output logic jtag_tdo_o,

  // Core interface
  input  logic        clk_i,
  input  logic        rst_ni,

  // Debug access to ternary components
  output logic [3:0]  debug_reg_addr,
  input  logic [31:0] debug_reg_data,
  output logic        debug_reg_read,

  // Status and control
  output logic        debug_enable,
  input  logic [31:0] debug_status
);

// JTAG TAP controller for ternary debug
// Implementation depends on your debug architecture
// (OpenOCD, Xilinx Debug Bridge, etc.)

endmodule
```

---

## Summary

This debug guide provides comprehensive tools and techniques for debugging the MHX Ternary Extension. Key debugging strategies include:

1. **Systematic Module Testing**: Debug each component in isolation
2. **Integration Verification**: Ensure proper signal connections
3. **Performance Analysis**: Monitor timing and throughput
4. **Automated Testing**: Use scripts for regression testing
5. **Hardware Validation**: FPGA-based verification

For additional support, refer to:
- `mhx_ternary_formal_spec.md` - Formal specifications
- `mhx_ternary_security_analysis.md` - Security considerations
- RTL source code comments and assertions
- Generated waveform files (`.vcd`) for detailed analysis

**Remember**: Always start with the simplest debug approach and progressively add complexity as needed. Use assertions liberally and trust your simulation tools.

---

**Document Status:** ACTIVE
**Maintenance:** Update with new debug techniques as discovered
**Support Contact:** MHX Neural Development Team