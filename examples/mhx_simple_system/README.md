# MHX Neural T1 Simple System (Prototype)

MHX Neural T1 Simple System provides an MHX Neural T1 (ternary-extended Ibex) based system simulated by Verilator that can run stand-alone binaries with ternary neural processing capabilities. It contains:

* An MHX Neural T1 Processor (Ibex with ternary extensions)
* A single memory for instructions and data
* GPIO controller for interfacing with LEDs and switches
* UART controller for debug output
* A basic peripheral to write ASCII output to a file and halt simulation from software
* A basic timer peripheral capable of generating interrupts based on the RISC-V Machine Timer Registers
* Support for ternary arithmetic operations and neural processing

## Prerequisites

You need the following tools installed:

* FuseSoC
* Verilator (for simulation)
* Python 3.6+
* RISC-V toolchain with ternary extension support

## Building Simulation

To build the simulation binary run:

```
fusesoc --cores-root=. run --target=sim --setup --build lowrisc:mhx:mhx_simple_system --RV32E=0 --RV32M=ibex_pkg::RV32MFast --SRAMInitFile=<sw_vmem_file>
```

`<sw_vmem_file>` should be a path to a vmem file containing the program to run. You can use the hello test from the regular simple system as a starting point.

## Building Software

MHX Neural T1 Simple System can run standard RISC-V binaries, with the addition of ternary instruction support. Software can be built using the same tools as the regular simple system.

For ternary-specific examples:

```
make -C examples/sw/mhx_system/ternary_test
```

## Running the Simulator

After building the simulation and software, run:

```
./build/lowrisc_mhx_mhx_simple_system_0/sim-verilator/Vmhx_simple_system
```

## MHX Neural T1 Extensions

The MHX Neural T1 Simple System includes the following ternary extensions:

### Ternary Arithmetic
- TADD, TSUB, TMUL - Ternary arithmetic operations
- TAND, TOR, TXOR, TNOT - Ternary logical operations

### Neural Processing
- NEURON - Perform full neuron computation in a single instruction
- ACTIVATE - Apply ternary activation functions
- LEARN - Update weights for learning

### Memory Map

| Device     | Base Address | Size | Description |
|------------|--------------|------|-------------|
| RAM        | 0x100000     | 1MB  | Main memory |
| SimCtrl    | 0x20000      | 1KB  | Simulation control |
| Timer      | 0x30000      | 1KB  | Timer peripheral |
| GPIO       | 0x40000      | 1KB  | GPIO controller |
| UART       | 0x50000      | 1KB  | UART controller |

### GPIO Controller

The GPIO controller provides 8 GPIO pins that can be configured as inputs or outputs:

* 0x40000: GPIO_OUT - Output data register
* 0x40004: GPIO_IN - Input data register (read-only)
* 0x40008: GPIO_DIR - Direction register (1=output, 0=input)

### UART Controller

The UART controller provides basic serial communication at 115200 baud:

* 0x50000: UART_DATA - Transmit/Receive data register
* 0x50004: UART_STATUS - Status register (bit 0: TX ready, bit 1: RX ready)
* 0x50008: UART_CTRL - Control register (bit 0: TX enable, bit 1: RX enable, bit 2: IRQ enable)

## FPGA Implementation

The MHX Neural T1 Simple System can be synthesized for FPGA implementation. See the `syn/fpga/` directory for FPGA-specific synthesis scripts and constraints.

## Examples

See `examples/sw/mhx_system/` for ternary-specific software examples demonstrating:

* Basic ternary arithmetic
* Neural network inference
* Performance comparisons between binary and ternary implementations