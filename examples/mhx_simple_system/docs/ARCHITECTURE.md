# MHX Simple System Architecture

## Overview

The MHX Simple System is a minimal but powerful System-on-Chip (SoC) designed to showcase the MHX core's ternary processing capabilities. It provides a complete development platform with essential peripherals, firmware examples, and FPGA implementation flows.

## System Architecture

```
                    MHX Simple System Architecture
                   ┌─────────────────────────────────┐
                   │          FPGA Top Level         │
                   │    (Clock, Reset, I/O Mapping) │
                   └─────────────┬───────────────────┘
                                 │
                   ┌─────────────▼───────────────────┐
                   │       MHX Simple System        │
                   │    (SoC with Bus Interconnect) │
                   └─────────────┬───────────────────┘
                                 │
        ┌────────────────────────┼────────────────────────┐
        │                        │                        │
┌───────▼────────┐    ┌─────────▼────────┐    ┌─────────▼────────┐
│   MHX Core     │    │   Memory System  │    │   Peripherals    │
│  (CPU + TExt)  │    │   (ROM + RAM)    │    │ (UART,GPIO,etc.) │
└────────────────┘    └──────────────────┘    └──────────────────┘
```

## MHX Core Features

### Standard RISC-V (RV32IMC)
- **I**: Integer base instruction set
- **M**: Integer multiplication and division
- **C**: Compressed instructions (16-bit)
- **Machine Mode**: Full privilege level support
- **CSR**: Control and Status Registers
- **Interrupts**: Machine-level interrupt handling

### Ternary Extensions (MHX)
- **16 Ternary Registers (T0-T15)**: Each 32 bits (16 trits)
- **Ternary ALU**: Native base-3 arithmetic and logic
- **Neural Processing Unit**: Specialized ML acceleration
- **Custom Instructions**: TADD, TSUB, TMUL, NEURON, etc.

### Performance Characteristics
- **Clock Frequency**: Up to 100 MHz on Artix-7
- **Pipeline**: 3-stage (Fetch, Decode/Execute, Writeback)
- **Memory Interface**: 32-bit AXI-like bus
- **Interrupt Latency**: ~10 clock cycles

## Memory System

### Memory Map
```
0x0000_0000 ┌─────────────────┐
            │      ROM        │ 64KB - Boot code, programs
            │   (Read Only)   │
0x0000_FFFF └─────────────────┘
            │                 │
0x1FFF_FFFF │   (Reserved)    │
            │                 │
0x2000_0000 ┌─────────────────┐
            │      RAM        │ 64KB - Runtime data, stack
            │  (Read/Write)   │
0x2000_FFFF └─────────────────┘
            │                 │
0x3FFF_FFFF │   (Reserved)    │
            │                 │
0x4000_0000 ┌─────────────────┐
            │      UART       │ 4KB - Serial interface
0x4000_0FFF └─────────────────┘
0x4001_0000 ┌─────────────────┐
            │      GPIO       │ 4KB - General purpose I/O
0x4001_0FFF └─────────────────┘
0x4002_0000 ┌─────────────────┐
            │     Timer       │ 4KB - System timer
0x4002_0FFF └─────────────────┘
0x4003_0000 ┌─────────────────┐
            │      SPI        │ 4KB - Serial Peripheral Interface
0x4003_0FFF └─────────────────┘
```

### Memory Hierarchy
- **ROM**: Contains bootloader and program code
- **RAM**: Runtime data, heap, and stack
- **No Cache**: Direct memory access for simplicity
- **Memory Protection**: Optional PMP support

## Peripheral Subsystem

### UART (Universal Asynchronous Receiver/Transmitter)
- **Base Address**: 0x4000_0000
- **Baud Rate**: 115200 (configurable)
- **Data Format**: 8N1 (8 data, no parity, 1 stop)
- **FIFO**: Optional TX/RX buffering
- **Interrupts**: TX/RX completion

#### Register Map
| Offset | Name      | Description |
|--------|-----------|-------------|
| 0x00   | TX_DATA   | Transmit data register |
| 0x00   | RX_DATA   | Receive data register |
| 0x04   | STATUS    | Status flags |
| 0x08   | CONTROL   | Control register |
| 0x0C   | BAUD_DIV  | Baud rate divisor |

### GPIO (General Purpose Input/Output)
- **Base Address**: 0x4001_0000
- **Width**: 8 bits
- **Direction**: Configurable per pin
- **Interrupts**: Edge/level triggered

#### Register Map
| Offset | Name      | Description |
|--------|-----------|-------------|
| 0x00   | OUT       | Output data register |
| 0x04   | OE        | Output enable register |
| 0x08   | IN        | Input data register |
| 0x0C   | IRQ_EN    | Interrupt enable |

### Timer
- **Base Address**: 0x4002_0000
- **Width**: 32 bits
- **Modes**: One-shot, continuous
- **Interrupts**: Compare match

#### Register Map
| Offset | Name      | Description |
|--------|-----------|-------------|
| 0x00   | COUNT     | Current count value |
| 0x04   | COMPARE   | Compare value |
| 0x08   | CTRL      | Control register |
| 0x0C   | STATUS    | Status register |

### SPI (Serial Peripheral Interface)
- **Base Address**: 0x4003_0000
- **Mode**: Master only
- **Clock**: Configurable frequency
- **Format**: Configurable CPOL/CPHA

## Bus Interconnect

### Simple Bus Protocol
- **Address Width**: 32 bits
- **Data Width**: 32 bits
- **Byte Enable**: 4 bits
- **Protocol**: Simple request/grant

### Address Decoding
```verilog
// Address decode logic
if (addr >= ROM_BASE && addr < ROM_BASE + ROM_SIZE)
    // Route to ROM
else if (addr >= RAM_BASE && addr < RAM_BASE + RAM_SIZE)
    // Route to RAM
else if (addr >= UART_BASE && addr < UART_BASE + UART_SIZE)
    // Route to UART
// ... etc
```

## Interrupt System

### Interrupt Sources
- **Timer**: Periodic or one-shot interrupts
- **UART**: TX/RX completion
- **GPIO**: Pin change detection
- **External**: Board-specific interrupts

### Interrupt Handling
- **RISC-V Standard**: Machine-level interrupts
- **Vector Table**: Configurable interrupt vectors
- **Priority**: Software-managed priority
- **Nesting**: Not supported (for simplicity)

## Clock and Reset

### Clock Distribution
- **Input Clock**: 100 MHz from board oscillator
- **System Clock**: Same as input (no PLL for simplicity)
- **Clock Gating**: Optional for power savings

### Reset Strategy
- **External Reset**: From board reset button
- **Internal Reset**: Synchronized reset release
- **Reset Domains**: Single domain for simplicity

## Power Management

### Power Domains
- **Core Domain**: CPU and critical logic
- **Peripheral Domain**: All peripherals
- **I/O Domain**: External interface logic

### Power Optimization
- **Clock Gating**: Unused modules can be gated
- **Voltage Scaling**: Not implemented
- **Sleep Modes**: Software-controlled WFI

## Ternary Processing

### Ternary Encoding
Each trit (ternary digit) uses 2 bits:
- `00` = -1 (negative)
- `01` = 0 (zero)
- `10` = +1 (positive)
- `11` = invalid (reserved)

### Ternary Operations
```
TADD T0, T1, T2    # T0 = T1 + T2 (ternary addition)
TSUB T0, T1, T2    # T0 = T1 - T2 (ternary subtraction)
TMUL T0, T1, T2    # T0 = T1 * T2 (ternary multiplication)
TAND T0, T1, T2    # T0 = min(T1, T2) (ternary AND)
TOR  T0, T1, T2    # T0 = max(T1, T2) (ternary OR)
TXOR T0, T1, T2    # T0 = T1 ⊕ T2 (ternary XOR)
TNOT T0, T1        # T0 = -T1 (ternary negation)
```

### Neural Processing
```
NEURON   T0, T1, T2    # T0 = neuron(weights=T1, inputs=T2)
NEURONA  T0, T1, T2    # T0 = accumulate(T1, T2)
ACTIVATE T0, T1        # T0 = activate(T1)
LEARN    T0, T1, T2    # T0 = learn(weights=T1, error=T2)
```

## Implementation Details

### FPGA Resource Usage (Artix-7 35T)
- **Logic Utilization**: ~6% (2000/33280 LUTs)
- **Memory**: ~8% (2-4/50 BRAM blocks)
- **DSP**: ~2% (0-2/90 DSP slices)
- **I/O**: 20+ pins for external interface

### Timing Characteristics
- **Maximum Frequency**: 100 MHz
- **Critical Paths**: Memory access, ALU operations
- **Setup/Hold**: Met with standard constraints
- **Clock Skew**: <500 ps

### Verification Strategy
- **Unit Tests**: Individual module testing
- **Integration Tests**: Full system simulation
- **FPGA Validation**: Hardware-in-the-loop testing
- **Software Tests**: Firmware validation

## Development Flow

### Simulation Flow
1. RTL development and unit testing
2. System-level integration testing
3. Firmware co-simulation
4. Performance analysis

### Synthesis Flow
1. RTL synthesis (Yosys or Vivado)
2. Place and route
3. Timing analysis and optimization
4. Bitstream generation

### Software Flow
1. Assembly/C code development
2. Cross-compilation for RISC-V
3. Memory image generation
4. Hardware-software co-debug

## Future Enhancements

### Potential Additions
- **Cache System**: Instruction and data caches
- **Memory Controller**: DDR3/DDR4 interface
- **Ethernet**: Network connectivity
- **Debug Interface**: JTAG debug support
- **Floating Point**: IEEE 754 support

### Performance Improvements
- **Pipeline Depth**: More stages for higher frequency
- **Branch Prediction**: Improve control flow performance
- **Superscalar**: Multiple instruction issue
- **Vector Processing**: SIMD ternary operations

### AI/ML Enhancements
- **Matrix Engine**: Dedicated matrix multiplication
- **Activation Functions**: Hardware accelerated functions
- **Quantization**: Dynamic precision support
- **Model Compression**: Sparse network support