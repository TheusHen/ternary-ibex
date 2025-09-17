# MHX Ternary RISC-V Implementation Guide

## Quick Start Guide

### Prerequisites

Ensure you have the following tools installed:

```bash
# Ubuntu/Debian packages
sudo apt-get update
sudo apt-get install -y \
    build-essential \
    git \
    python3 \
    python3-pip \
    verilator \
    yosys \
    magic \
    klayout \
    gtkwave

# Python packages
pip3 install \
    fusesoc \
    cocotb \
    pytest \
    numpy \
    matplotlib
```

### Installation

1. **Clone Repository**
```bash
git clone https://github.com/mhx-neural/ternary-ibex.git
cd ternary-ibex
```

2. **Setup FuseSoC**
```bash
# Add core library
fusesoc library add mhx_ternary ./
fusesoc core list | grep mhx
```

3. **Verify Installation**
```bash
# Run basic test
fusesoc run --target=sim mhx:ibex:ternary_test
```

### First Simulation

```bash
# Compile and run ternary ALU test
cd dv
make ternary_basic_test

# View waveforms
gtkwave ternary_basic_test.vcd
```

## Detailed Setup Instructions

### Development Environment

#### Option 1: Local Installation

**Install Open Source EDA Tools**

```bash
# Install Yosys (synthesis)
git clone https://github.com/YosysHQ/yosys.git
cd yosys
make config-gcc
make -j$(nproc)
sudo make install

# Install Verilator (simulation)
git clone https://github.com/verilator/verilator.git
cd verilator
autoconf
./configure
make -j$(nproc)
sudo make install

# Install Magic (layout)
git clone https://github.com/RTimothyEdwards/magic.git
cd magic
./configure
make -j$(nproc)
sudo make install
```

#### Option 2: Docker Container

```bash
# Pull pre-configured container
docker pull mhxneural/ternary-riscv-dev:latest

# Run development container
docker run -it --rm \
    -v $(pwd):/workspace \
    -w /workspace \
    mhxneural/ternary-riscv-dev:latest
```

#### Option 3: GitHub Codespaces

1. Fork the repository
2. Open in GitHub Codespaces
3. Environment automatically configured

### Toolchain Configuration

#### RISC-V GCC Setup

```bash
# Download prebuilt toolchain
wget https://github.com/riscv/riscv-gnu-toolchain/releases/download/2023.10.18/riscv32-elf-ubuntu-20.04-gcc-nightly-2023.10.18-nightly.tar.gz

# Extract and setup
tar -xzf riscv32-elf-ubuntu-20.04-gcc-nightly-2023.10.18-nightly.tar.gz
export PATH=$PATH:$(pwd)/riscv/bin

# Verify installation
riscv32-unknown-elf-gcc --version
```

#### Custom Ternary Extensions

```bash
# Build ternary-aware assembler
cd tools/assembler
make ternary-as
sudo make install

# Build ternary compiler
cd tools/compiler  
make ternary-gcc
sudo make install
```

## Project Structure

```
ternary-ibex/
├── rtl/                    # RTL source files
│   ├── ibex_ternary_alu.sv       # Ternary ALU implementation
│   ├── ibex_ternary_regfile.sv   # Ternary register file
│   ├── ibex_neural_unit.sv       # Neural processing unit
│   └── ibex_pkg.sv               # Package definitions
├── dv/                     # Design verification
│   ├── mhx_ternary_test_main.cpp # Main testbench
│   ├── mhx_ternary_test.sv       # SystemVerilog testbench
│   └── verilator/                # Verilator configuration
├── synthesis/              # Synthesis scripts
│   ├── synthesize_ternary_alu.py # Main synthesis script
│   └── ternary_alu_verilog.v     # Synthesized output
├── timing/                 # Timing analysis
│   ├── timing_analysis.py        # Timing analysis script
│   └── results/                  # Timing reports
├── openlane/              # OpenLane ASIC flow
│   ├── config.tcl               # OpenLane configuration
│   └── run_openlane.sh          # Execution script
├── gdsii/                 # GDSII generation
│   ├── generate_gdsii_final.py  # GDSII generation
│   └── final/                   # Output files
├── place_route/           # Place & Route automation
│   ├── automated_pnr_master.py  # Master P&R script
│   └── scripts/                 # Individual stage scripts
├── documentation/         # Technical documentation
│   └── *.md                     # Markdown documentation
├── examples/              # Example programs
│   ├── mhx_demo.s              # Assembly demo
│   └── sw/                     # Software examples
└── tools/                 # Development tools
    ├── assembler/              # Ternary assembler
    └── compiler/               # Ternary compiler
```

## Build Process

### Simulation Flow

#### 1. RTL Compilation

```bash
# Using FuseSoC
fusesoc run --target=sim mhx:ibex:ternary_test

# Manual compilation
cd dv/verilator
verilator --cc --exe \
    -I../../rtl \
    --top-module mhx_ternary_test \
    ../../rtl/ibex_ternary_alu.sv \
    mhx_ternary_test_main.cpp
```

#### 2. Test Execution

```bash
# Run all tests
make test_all

# Run specific test
make test_ternary_add

# Run with coverage
make test_coverage
```

#### 3. Debug and Analysis

```bash
# Generate waveforms
make waves TESTCASE=ternary_neural

# View in GTKWave
gtkwave ternary_neural.vcd ternary_neural.gtkw

# Coverage analysis
make coverage_report
firefox coverage_html/index.html
```

### Synthesis Flow

#### 1. RTL Synthesis

```bash
cd synthesis
python3 synthesize_ternary_alu.py

# Expected output:
# Gate count: 1,184
# Area: 2,450 µm²
# Timing: Meets 100MHz target
```

#### 2. Technology Mapping

```bash
# Map to SkyWater 130nm
yosys -s synthesis_script.ys

# Verify netlist
yosys -p "read_verilog ternary_alu_verilog.v; check"
```

#### 3. Timing Analysis

```bash
cd timing
python3 timing_analysis.py

# Review results
cat results/timing_summary.json
```

### ASIC Implementation Flow

#### 1. OpenLane Flow

```bash
cd openlane
./run_openlane.sh

# Monitor progress
tail -f runs/latest/logs/synthesis/yosys.log
```

#### 2. Place and Route

```bash
cd place_route
python3 automated_pnr_master.py

# Expected results:
# Utilization: 67.3%
# Wirelength: 2,847 µm
# DRC violations: 0
```

#### 3. GDSII Generation

```bash
cd gdsii
python3 generate_gdsii_final.py

# Verify output
ls -la final/
# ibex_ternary_alu_verilog.gds
# ibex_ternary_alu_verilog.lef
# ibex_ternary_alu_verilog.def
```

## Testing and Verification

### Unit Tests

#### Ternary ALU Tests

```bash
cd dv/unit_tests
python3 test_ternary_alu.py

# Test cases:
# - Basic arithmetic (add, sub, mul)
# - Logic operations (and, or, xor, not)
# - Edge cases and error conditions
# - Performance benchmarks
```

#### Neural Unit Tests

```bash
python3 test_neural_unit.py

# Test cases:
# - Dot product operations
# - Convolution functions
# - Activation functions
# - Vector operations
```

### Integration Tests

#### System-Level Tests

```bash
cd dv/integration
make system_test

# Tests:
# - Full instruction execution
# - Memory interface
# - Exception handling
# - Performance validation
```

#### RISC-V Compliance

```bash
# Run official RISC-V compliance tests
cd dv/riscv_compliance
make compliance_test

# Expected: All tests pass
# Tests: RV32I base instruction set
```

### Formal Verification

#### Setup Formal Tools

```bash
# Install SymbiYosys
git clone https://github.com/YosysHQ/sby.git
cd sby
make install

# Install SMT solvers
sudo apt-get install z3 boolector
```

#### Run Formal Verification

```bash
cd formal
sby -f ternary_alu.sby

# Verify properties:
# - Arithmetic correctness
# - Register file safety
# - Bus protocol compliance
```

## Performance Optimization

### Synthesis Optimization

#### Area Optimization

```bash
# Optimize for minimum area
yosys -p "
    read_verilog rtl/ibex_ternary_alu.sv;
    synth -top ibex_ternary_alu;
    opt_clean;
    opt -fine;
    techmap;
    opt;
    abc -D 1000;
    opt_clean
"
```

#### Timing Optimization

```bash
# Optimize for maximum frequency
yosys -p "
    read_verilog rtl/ibex_ternary_alu.sv;
    synth -top ibex_ternary_alu;
    dfflibmap -liberty sky130_fd_sc_hd.lib;
    abc -liberty sky130_fd_sc_hd.lib -D 100;
    write_verilog optimized_alu.v
"
```

#### Power Optimization

```bash
# Clock gating for power reduction
yosys -p "
    read_verilog rtl/ibex_ternary_alu.sv;
    synth -top ibex_ternary_alu;
    clockgate;
    opt_clean;
    write_verilog power_optimized_alu.v
"
```

### Software Optimization

#### Ternary Code Optimization

```c
// Efficient ternary operations
static inline ternary_t fast_ternary_add(ternary_t a, ternary_t b) {
    // Use hardware acceleration
    register ternary_t result asm("t1");
    asm volatile (
        "tadd %0, %1, %2"
        : "=r" (result)
        : "r" (a), "r" (b)
        : "memory"
    );
    return result;
}

// Vectorized ternary operations
void ternary_vector_add(ternary_t *a, ternary_t *b, ternary_t *result, int n) {
    for (int i = 0; i < n; i += 8) {
        // Process 8 elements at once using SIMD-style operations
        asm volatile (
            "tadd.8 %0, %1, %2"
            : "=r" (*(result + i))
            : "r" (*(a + i)), "r" (*(b + i))
        );
    }
}
```

## Troubleshooting

### Common Issues

#### Simulation Failures

**Problem**: Verilator compilation errors
```bash
# Solution: Check RTL syntax
verilator --lint-only rtl/ibex_ternary_alu.sv

# Fix common issues:
# - Missing include paths
# - Undefined parameters
# - Clock domain crossing
```

**Problem**: Test failures
```bash
# Debug with waveforms
make test_debug TESTCASE=failing_test
gtkwave test_output.vcd

# Check assertion failures
grep -r "ASSERTION FAILED" logs/
```

#### Synthesis Issues

**Problem**: Timing violations
```bash
# Solution: Analyze critical path
sta -report_timing -max_paths 10

# Add pipeline registers
# Reduce logic depth
# Use faster library cells
```

**Problem**: Area violations
```bash
# Solution: Optimize for area
yosys -p "synth -flatten; opt_expr; opt_clean"

# Share common logic
# Remove redundant logic
# Use smaller library cells
```

#### Implementation Problems

**Problem**: DRC violations
```bash
# Solution: Fix layout issues
magic -T sky130A
# load layout
# drc check
# drc why

# Common fixes:
# - Increase spacing
# - Fix minimum width
# - Add proper enclosure
```

**Problem**: LVS mismatches
```bash
# Solution: Compare netlist and layout
netgen -batch lvs "layout.spice layout_cell" "netlist.spice netlist_cell"

# Common issues:
# - Missing connections
# - Device parameter mismatches
# - Floating nodes
```

### Debug Techniques

#### RTL Debugging

```systemverilog
// Add debug probes
module debug_ternary_alu;
    // Monitor signals
    always @(posedge clk_i) begin
        if (valid_o) begin
            $display("Operation: %s, A: %h, B: %h, Result: %h",
                     operation_name(operation_i), operand_a_i, operand_b_i, result_o);
        end
    end
    
    // Assertions for correctness
    property ternary_add_correct;
        @(posedge clk_i) 
        (operation_i == TADD) |-> 
        ##1 (result_o == expected_ternary_add(operand_a_i, operand_b_i));
    endproperty
    
    assert property (ternary_add_correct);
endmodule
```

#### Performance Debugging

```python
# Python performance analyzer
import json
import matplotlib.pyplot as plt

def analyze_performance(results_file):
    with open(results_file) as f:
        data = json.load(f)
    
    # Plot timing histogram
    delays = [path['delay'] for path in data['timing_paths']]
    plt.hist(delays, bins=50)
    plt.xlabel('Delay (ns)')
    plt.ylabel('Number of Paths')
    plt.title('Timing Distribution')
    plt.show()
    
    # Identify critical paths
    critical_paths = [path for path in data['timing_paths'] 
                     if path['delay'] > data['clock_period'] * 0.9]
    
    for path in critical_paths:
        print(f"Critical path: {path['start']} -> {path['end']}")
        print(f"Delay: {path['delay']} ns")
```

## Continuous Integration

### GitHub Actions Workflow

```yaml
name: MHX Ternary RISC-V CI

on: [push, pull_request]

jobs:
  simulation:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Install tools
      run: |
        sudo apt-get update
        sudo apt-get install verilator yosys
        pip install fusesoc cocotb
    
    - name: Run simulation tests
      run: |
        cd dv
        make test_all
    
    - name: Upload coverage
      uses: codecov/codecov-action@v3
      with:
        files: coverage/coverage.xml

  synthesis:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Run synthesis
      run: |
        cd synthesis
        python3 synthesize_ternary_alu.py
    
    - name: Check timing
      run: |
        cd timing
        python3 timing_analysis.py
        
    - name: Archive results
      uses: actions/upload-artifact@v3
      with:
        name: synthesis-results
        path: synthesis/results/
```

### Quality Gates

#### Code Quality Checks

```bash
# RTL linting
verilator --lint-only rtl/*.sv

# Python code quality
flake8 scripts/
black --check scripts/
mypy scripts/

# Documentation checks
markdownlint documentation/*.md
```

#### Performance Gates

```bash
# Timing requirements
python3 check_timing.py --max_delay 10.0 --min_frequency 100

# Area requirements  
python3 check_area.py --max_area 5000

# Power requirements
python3 check_power.py --max_power 1000
```

## Getting Help

### Documentation

- **Technical Documentation**: See `documentation/` directory
- **API Reference**: Generated from RTL comments
- **Examples**: Check `examples/` directory

### Community Support

- **GitHub Issues**: Report bugs and feature requests
- **Discussions**: Ask questions in GitHub Discussions
- **Discord**: Join the MHX Neural Discord server

### Commercial Support

For commercial support, training, and custom implementations:
- Email: support@mhx-neural.com
- Website: https://mhx-neural.com

---

**Last Updated**: December 2024  
**Version**: 1.0  
**Maintainer**: MHX Neural Research Team