# FPGA Synthesis for MHX Simple System

This directory contains FPGA synthesis scripts and constraints for implementing the MHX Simple System (ternary-extended Ibex) on various FPGA development boards.

## Supported Boards

### Digilent Arty A7
- **FPGA**: Xilinx Artix-7 XC7A35T
- **Clock**: 100MHz input, 50MHz system clock
- **Resources**: 4 LEDs, 4 buttons, 4 switches, UART
- **Files**: `arty_a7/`

### Digilent Basys3
- **FPGA**: Xilinx Artix-7 XC7A35T
- **Clock**: 100MHz input, 50MHz system clock  
- **Resources**: 4 LEDs, 5 buttons (including reset), 4 switches, UART
- **Files**: `basys3/`

## Prerequisites

- Xilinx Vivado (2020.1 or later)
- MHX Simple System RTL files
- RISC-V toolchain for firmware compilation

## Building for FPGA

### Quick Start

1. Build for Arty A7:
```bash
./build_fpga.sh arty_a7
```

2. Build for Basys3:
```bash
./build_fpga.sh basys3
```

### Manual Build

1. Navigate to the target board directory:
```bash
cd arty_a7  # or basys3
```

2. Run Vivado with the build script:
```bash
vivado -mode batch -source build_arty_a7.tcl  # or build_basys3.tcl
```

3. The bitstream will be generated in the project directory.

## Hardware Interface

### GPIO Mapping

| Signal     | Arty A7 Pin | Basys3 Pin | Description |
|------------|-------------|------------|-------------|
| clk_100mhz | E3          | W5         | 100MHz input clock |
| rst_btn_n  | C2          | U18        | Reset button (active low) |
| led_o[0]   | H5          | U16        | LED 0 |
| led_o[1]   | J5          | E19        | LED 1 |
| led_o[2]   | T9          | U19        | LED 2 |
| led_o[3]   | T10         | V19        | LED 3 |
| btn_i[0]   | D9          | T18        | Button 0 |
| btn_i[1]   | C9          | W19        | Button 1 |
| btn_i[2]   | B9          | T17        | Button 2 |
| btn_i[3]   | B8          | U17        | Button 3 |
| sw_i[0]    | A8          | V17        | Switch 0 |
| sw_i[1]    | C11         | V16        | Switch 1 |
| sw_i[2]    | C10         | W16        | Switch 2 |
| sw_i[3]    | A10         | W17        | Switch 3 |
| uart_tx    | A9          | A18        | UART transmit |
| uart_rx    | D10         | B18        | UART receive |

### Memory Map

The FPGA implementation uses the same memory map as the simulation:

| Device     | Base Address | Size | Description |
|------------|--------------|------|-------------|
| RAM        | 0x100000     | 1MB  | Main memory |
| SimCtrl    | 0x20000      | 1KB  | Simulation control |
| Timer      | 0x30000      | 1KB  | Timer peripheral |
| GPIO       | 0x40000      | 1KB  | GPIO controller |
| UART       | 0x50000      | 1KB  | UART controller |

## Firmware

To run software on the FPGA, you need to compile firmware and initialize the RAM:

1. Compile your C/assembly program to generate a `.vmem` file
2. Update the `SRAMInitFile` parameter in the TCL script
3. Rebuild the FPGA bitstream

Example firmware memory initialization:
```tcl
set_property -dict [list CONFIG.SRAMInitFile {firmware.vmem}] [get_cells u_mhx_system]
```

## Ternary Extensions on FPGA

The FPGA implementation includes all MHX ternary extensions:

- **Ternary ALU**: Hardware acceleration for ternary arithmetic
- **Neural Processing Unit**: Single-cycle neural operations  
- **Ternary Register File**: Native ternary data storage
- **Extended Decoder**: Support for ternary instruction decoding

## Performance

Typical synthesis results on Artix-7:

- **System Clock**: 50MHz
- **Logic Utilization**: ~15% of XC7A35T
- **Memory**: ~60% Block RAM
- **Ternary Operations**: 1 cycle latency
- **Neural Operations**: 1 cycle latency

## Debugging

### UART Console

Connect to the UART (115200 baud, 8N1) to see debug output from the MHX system:

```bash
screen /dev/ttyUSB1 115200  # Linux
# or use PuTTY on Windows
```

### ILA (Integrated Logic Analyzer)

To add signal probing for debugging:

1. Modify the TCL script to insert ILA cores
2. Add signals of interest to the ILA
3. Use Vivado Hardware Manager to capture traces

### LEDs and Switches

- **LEDs**: Show GPIO output values from the MHX system
- **Switches**: Provide input to the MHX system via GPIO
- **Buttons**: Can trigger interrupts or provide additional input

## Troubleshooting

### Synthesis Errors

If synthesis fails:
1. Check that all RTL files are included
2. Verify SystemVerilog support is enabled
3. Check for missing IP cores (clk_wiz_0)

### Timing Closure

If timing constraints are not met:
1. Reduce system clock frequency
2. Add pipeline stages to critical paths
3. Use faster speed grade FPGA

### Programming Issues

If bitstream programming fails:
1. Check board power and USB connections
2. Verify correct board/part selection
3. Try programming in Vivado Hardware Manager GUI

## Future Enhancements

- Support for additional FPGA boards (Kintex, Zynq)
- DDR memory controller integration
- Ethernet interface for remote debugging
- Advanced ternary instruction visualization
- Hardware accelerated neural network demos