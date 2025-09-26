# MHX Neural T1 Quick Start Guide

This guide helps you get started with the MHX Neural T1 Simple System (Prototype) - a ternary-extended RISC-V processor with neural processing capabilities.

## 🚀 Quick Validation

First, validate that your MHX implementation is complete:

```bash
python3 util/mhx_simple_validator.py
```

This will check all required files without needing external tools.

## 📋 Prerequisites

### Required Tools
- **FuseSoC** - Core build system
- **Verilator** - Simulation
- **RISC-V Toolchain** - Software compilation
- **Python 3** - Test scripts

### Installation (Ubuntu/Debian)
```bash
# Install FuseSoC
pip3 install fusesoc

# Install Verilator
sudo apt install verilator

# Install RISC-V toolchain (example)
# Download from: https://github.com/lowRISC/lowrisc-toolchains/releases
```

## 🔧 Building the MHX System

### 1. Build the MHX Simple System
```bash
make build-mhx-system
```

### 2. Build Software Examples
```bash
# Build MHX hello world example
make -C examples/sw/mhx_system/hello_mhx

# Build test programs
make -C dv/mhx_simple_system_tests/test_programs
```

### 3. Run Simulation
```bash
make run-mhx-system
```

## 🧪 Testing

### Run All Tests
```bash
make test-mhx-all
```

### Individual Test Suites
```bash
make test-mhx-lint      # Code quality checks
make test-mhx-build     # Build tests
make test-mhx-sim       # Simulation tests  
make test-mhx-fpga      # FPGA validation
```

### Manual Test Runner
```bash
# Run specific test suite
util/mhx_tests/run_mhx_tests.sh fpga
util/mhx_tests/run_mhx_tests.sh all
```

## 🔌 FPGA Deployment

### Supported Boards
- **Digilent Arty A7** (Artix-7 XC7A35T)
- **Digilent Basys3** (Artix-7 XC7A35T)

### Build for FPGA
```bash
cd syn/fpga

# Build for Arty A7
./build_fpga.sh arty_a7

# Build for Basys3
./build_fpga.sh basys3
```

### Hardware Interface
- **4 LEDs** - GPIO output visualization
- **4 Buttons + 4 Switches** - User input
- **UART** - Serial console (115200 baud)

## 🎯 What's Included

### Core Components
- **MHX Neural T1 Core** - Ternary-extended Ibex processor
- **Ternary ALU** - Hardware ternary arithmetic operations
- **Neural Processing Unit** - Accelerated neural operations
- **GPIO Controller** - 8-bit LED/switch interface
- **UART Controller** - Serial debug capability
- **Timer Peripheral** - Interrupt generation

### Memory Map
```
0x00100000 - 0x001FFFFF : RAM (1MB)
0x80000000 - 0x8000000F : GPIO
0x80001000 - 0x8000100F : UART  
0x80002000 - 0x8000200F : Timer
0x80003000 - 0x8000300F : Simulation Control
```

### Software Examples
- **hello_mhx.c** - Basic ternary operations demo
- **mhx_test_program.c** - Comprehensive system test

## 🔍 Troubleshooting

### Common Issues

**Build fails with "fusesoc not found"**
```bash
pip3 install fusesoc
```

**Simulation fails with "Verilator not found"**
```bash
sudo apt install verilator
```

**Software compilation fails**
```bash
# Check RISC-V toolchain installation
riscv32-unknown-elf-gcc --version
```

**Validation mode (no external tools)**
```bash
# Run without FuseSoC/Verilator
python3 util/mhx_simple_validator.py
```

### Getting Help

1. **Validate first**: `python3 util/mhx_simple_validator.py`
2. **Check documentation**: `examples/mhx_simple_system/README.md`
3. **Run tests**: `make test-mhx-all`
4. **Check workflows**: GitHub Actions provide continuous validation

## 🏗️ Architecture Overview

```
MHX Neural T1 Simple System:
├── MHX Neural T1 Core (RV32IMC + Ternary Extensions)
│   ├── Standard RISC-V Pipeline
│   ├── Ternary Register File (16 × 32-trit registers)
│   ├── Ternary ALU (TADD, TSUB, TMUL, TAND, TOR, TXOR, TNOT)
│   └── Neural Processing Unit (NEURON, ACTIVATE, LEARN)
├── Memory Subsystem (1MB RAM)
├── GPIO Controller (8-bit interface)
├── UART Controller (115200 baud)
└── Timer Peripheral
```

## 🚀 Next Steps

1. **Simulation**: Build and run the MHX system in simulation
2. **FPGA Deployment**: Deploy to hardware for real-world testing
3. **Software Development**: Create applications using ternary operations
4. **Neural Applications**: Implement neural networks with hardware acceleration

---

**MHX Neural T1 (Prototype)** - Ternary-enhanced RISC-V for neural processing applications