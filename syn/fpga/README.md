# MHX™ Ternary Extension - FPGA Demo

This directory contains the FPGA implementation of the MHX™ Ternary Extension demonstration.

## Supported Boards

| Board | FPGA | Status |
|-------|------|--------|
| Digilent Arty A7-35T | XC7A35T | ✅ Primary |
| Lattice iCE40 HX8K | iCE40HX8K | 🚧 Planned |

## Features

The FPGA demo showcases:

1. **Ternary ALU Operations**: Visualize ADD, SUB, MUL, AND, OR, XOR, NOT
2. **Neural Inference**: Simple dot product demonstration
3. **Register File**: Read/write ternary registers
4. **LED Visualization**: Trit values shown as colors

## Hardware Requirements

### Arty A7-35T

- Digilent Arty A7-35T board
- Micro USB cable
- Vivado 2023.1 or later

### Controls

| Control | Function |
|---------|----------|
| SW[1:0] | Mode select (00=ALU, 01=Neural, 10=RegFile, 11=Perf) |
| BTN0 | Mode-specific function 1 |
| BTN1 | Mode-specific function 2 |
| BTN2 | Mode-specific function 3 |
| BTN3 | Mode-specific function 4 |

### LED Output

| LED | Function |
|-----|----------|
| LED0 | Result trit 0 (+1 = on) |
| LED1 | ALU overflow indicator |
| LED2 | Neural valid indicator |
| LED3 | Heartbeat (system running) |

### RGB LED Output

Each RGB LED shows one trit of the result:
- **Red**: -1 (TRIT_NEG)
- **Off**: 0 (TRIT_ZERO)
- **Green**: +1 (TRIT_POS)
- **Blue**: Invalid encoding

## Building

### Prerequisites

```bash
# Vivado for Arty A7
source /opt/Xilinx/Vivado/2023.1/settings64.sh

# Or OSS CAD Suite for iCE40
# https://github.com/YosysHQ/oss-cad-suite-build
```

### Arty A7

```bash
cd syn/fpga
make arty
make program_arty
```

### iCE40 (Yosys + nextpnr)

```bash
cd syn/fpga
make ice40
make program_ice40
```

## File Structure

```
fpga/
├── Makefile              # Build automation
├── mhx_fpga_top.sv       # Top-level demo module
├── constraints/
│   ├── arty_a7.xdc       # Arty A7 pin constraints
│   └── ice40_hx8k.pcf    # iCE40 pin constraints
├── scripts/
│   ├── synth_arty.tcl    # Vivado synthesis script
│   └── program_arty.tcl  # Vivado programming script
├── build/                # Build artifacts
└── bitstream/            # Output bitstreams
```

## Demo Modes

### Mode 0: Ternary ALU Demo

Demonstrates all 7 ternary ALU operations:

1. Press BTN0 to cycle through operations (ADD→SUB→MUL→AND→OR→XOR→NOT)
2. Press BTN1 to change operand A (-1→0→+1)
3. Press BTN2 to change operand B (-1→0→+1)
4. RGB LEDs show the result

### Mode 1: Neural Inference Demo

Demonstrates neural unit dot product:

1. Press BTN0 to set weights pattern
2. Press BTN1 to set inputs pattern
3. Press BTN2 to set bias
4. Press BTN3 to run activation
5. LED2 lights when result is valid

### Mode 2: Register File Demo

Demonstrates ternary register file:

1. Press BTN0 to select register (T0-T31)
2. Press BTN1 to write pattern
3. RGB LEDs show register contents

### Mode 3: Performance Counter Demo

Shows operation counters and heartbeat.

## Resource Utilization (Estimated)

| Resource | Arty A7-35T | Utilization |
|----------|-------------|-------------|
| LUTs | ~2,000 | ~6% |
| FFs | ~1,500 | ~4% |
| BRAM | 0 | 0% |
| DSP | 0 | 0% |

## Performance

| Metric | Value |
|--------|-------|
| Max Frequency | 100 MHz |
| Demo Clock | 50 MHz |
| Latency (ALU) | 1 cycle |
| Latency (Neural) | 1 cycle |

## Troubleshooting

### Vivado Not Found

```bash
export PATH=/opt/Xilinx/Vivado/2023.1/bin:$PATH
```

### Board Not Detected

Check USB connection and install Digilent drivers:
```bash
sudo apt install libftdi-dev
```

### Synthesis Errors

Ensure all RTL files are present:
```bash
ls -la ../../rtl/ibex_ternary_*.sv
```
