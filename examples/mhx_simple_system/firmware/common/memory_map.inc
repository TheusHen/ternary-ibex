# Copyright lowRISC contributors.
# Copyright 2025 MHX™ Neural.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

/**
 * MHX™ Simple System Memory Map Definitions
 * 
 * This file contains memory map constants and register definitions
 * for the MHX™ Simple System. Include this file in assembly programs
 * to access system peripherals.
 *
 * Usage:
 *   .include "memory_map.inc"
 */

# ============================================================================
# Base Addresses
# ============================================================================

# Memory regions
.equ ROM_BASE,   0x00000000  # ROM base address (64KB)
.equ ROM_SIZE,   0x00010000  # ROM size
.equ RAM_BASE,   0x20000000  # RAM base address (64KB)  
.equ RAM_SIZE,   0x00010000  # RAM size

# Peripheral base addresses
.equ UART_BASE,  0x40000000  # UART peripheral base
.equ GPIO_BASE,  0x40010000  # GPIO peripheral base
.equ TIMER_BASE, 0x40020000  # Timer peripheral base
.equ SPI_BASE,   0x40030000  # SPI peripheral base (optional)

# ============================================================================
# UART Peripheral Registers
# ============================================================================

# UART register offsets from UART_BASE
.equ UART_TX_DATA,    0x00   # Transmit data register
.equ UART_RX_DATA,    0x00   # Receive data register (same as TX)
.equ UART_STATUS,     0x04   # Status register
.equ UART_CONTROL,    0x08   # Control register
.equ UART_BAUD_DIV,   0x0C   # Baud rate divisor register

# UART status register bits
.equ UART_TX_READY,   0x01   # Transmit ready
.equ UART_RX_READY,   0x02   # Receive ready
.equ UART_TX_EMPTY,   0x04   # Transmit buffer empty
.equ UART_RX_FULL,    0x08   # Receive buffer full
.equ UART_TX_IRQ,     0x10   # Transmit interrupt pending
.equ UART_RX_IRQ,     0x20   # Receive interrupt pending

# UART control register bits
.equ UART_TX_EN,      0x01   # Transmit enable
.equ UART_RX_EN,      0x02   # Receive enable
.equ UART_TX_IRQ_EN,  0x04   # Transmit interrupt enable
.equ UART_RX_IRQ_EN,  0x08   # Receive interrupt enable

# Common UART configurations
.equ UART_BAUD_115200, 54    # Baud divisor for 115200 @ 100MHz
.equ UART_BAUD_57600,  108   # Baud divisor for 57600 @ 100MHz
.equ UART_BAUD_38400,  162   # Baud divisor for 38400 @ 100MHz
.equ UART_BAUD_9600,   651   # Baud divisor for 9600 @ 100MHz

# ============================================================================
# GPIO Peripheral Registers
# ============================================================================

# GPIO register offsets from GPIO_BASE
.equ GPIO_OUT,        0x00   # Output data register
.equ GPIO_OE,         0x04   # Output enable register
.equ GPIO_IN,         0x08   # Input data register
.equ GPIO_IRQ_EN,     0x0C   # Interrupt enable register
.equ GPIO_IRQ_TYPE,   0x10   # Interrupt type register (level/edge)
.equ GPIO_IRQ_POL,    0x14   # Interrupt polarity register
.equ GPIO_IRQ_STATUS, 0x18   # Interrupt status register

# GPIO bit masks (for 8-bit GPIO)
.equ GPIO_PIN0,       0x01
.equ GPIO_PIN1,       0x02
.equ GPIO_PIN2,       0x04
.equ GPIO_PIN3,       0x08
.equ GPIO_PIN4,       0x10
.equ GPIO_PIN5,       0x20
.equ GPIO_PIN6,       0x40
.equ GPIO_PIN7,       0x80
.equ GPIO_ALL_PINS,   0xFF

# Common GPIO patterns
.equ GPIO_LED_PATTERN1, 0x55  # Alternating pattern
.equ GPIO_LED_PATTERN2, 0xAA  # Inverse alternating
.equ GPIO_LED_WALKING,  0x01  # Walking bit start

# ============================================================================
# Timer Peripheral Registers
# ============================================================================

# Timer register offsets from TIMER_BASE
.equ TIMER_COUNT,     0x00   # Current count register
.equ TIMER_COMPARE,   0x04   # Compare value register
.equ TIMER_CTRL,      0x08   # Control register
.equ TIMER_STATUS,    0x0C   # Status register

# Timer control register bits
.equ TIMER_EN,        0x01   # Timer enable
.equ TIMER_IRQ_EN,    0x02   # Interrupt enable
.equ TIMER_ONESHOT,   0x04   # One-shot mode (vs continuous)
.equ TIMER_RESET,     0x08   # Reset counter

# Timer status register bits
.equ TIMER_IRQ,       0x01   # Interrupt pending
.equ TIMER_RUNNING,   0x02   # Timer running

# Timer configurations (assuming 100MHz system clock)
.equ TIMER_1MS,       100000    # 1 millisecond
.equ TIMER_10MS,      1000000   # 10 milliseconds
.equ TIMER_100MS,     10000000  # 100 milliseconds
.equ TIMER_1S,        100000000 # 1 second

# ============================================================================
# SPI Peripheral Registers (Optional)
# ============================================================================

# SPI register offsets from SPI_BASE
.equ SPI_DATA,        0x00   # Data register (TX/RX)
.equ SPI_CTRL,        0x04   # Control register
.equ SPI_STATUS,      0x08   # Status register
.equ SPI_BAUD_DIV,    0x0C   # Baud rate divisor

# SPI control register bits
.equ SPI_EN,          0x01   # SPI enable
.equ SPI_MSTR,        0x02   # Master mode
.equ SPI_CPOL,        0x04   # Clock polarity
.equ SPI_CPHA,        0x08   # Clock phase
.equ SPI_IRQ_EN,      0x10   # Interrupt enable

# SPI status register bits
.equ SPI_TX_READY,    0x01   # Transmit ready
.equ SPI_RX_READY,    0x02   # Receive ready
.equ SPI_BUSY,        0x04   # Transfer in progress
.equ SPI_IRQ,         0x08   # Interrupt pending

# ============================================================================
# System Control and Status
# ============================================================================

# System clock frequency
.equ SYS_CLK_FREQ,    100000000  # 100 MHz

# Reset and boot addresses
.equ RESET_VECTOR,    ROM_BASE
.equ BOOT_VECTOR,     ROM_BASE

# ============================================================================
# Interrupt and Exception Vectors
# ============================================================================

# Exception causes (mcause register values)
.equ EXC_INSTR_MISALIGN,    0   # Instruction address misaligned
.equ EXC_INSTR_FAULT,       1   # Instruction access fault
.equ EXC_ILLEGAL_INSTR,     2   # Illegal instruction
.equ EXC_BREAKPOINT,        3   # Breakpoint
.equ EXC_LOAD_MISALIGN,     4   # Load address misaligned
.equ EXC_LOAD_FAULT,        5   # Load access fault
.equ EXC_STORE_MISALIGN,    6   # Store address misaligned
.equ EXC_STORE_FAULT,       7   # Store access fault
.equ EXC_ECALL_U,           8   # Environment call from U-mode
.equ EXC_ECALL_S,           9   # Environment call from S-mode
.equ EXC_ECALL_M,          11   # Environment call from M-mode

# Interrupt causes (mcause register values with MSB set)
.equ IRQ_SOFTWARE,     0x80000003  # Software interrupt
.equ IRQ_TIMER,        0x80000007  # Timer interrupt
.equ IRQ_EXTERNAL,     0x8000000B  # External interrupt

# MHX™ Simple System specific interrupts
.equ IRQ_UART,         16   # UART interrupt
.equ IRQ_GPIO,         17   # GPIO interrupt
.equ IRQ_SPI,          18   # SPI interrupt

# ============================================================================
# MHX™ Ternary Extension Constants
# ============================================================================

# Ternary register file (T0-T15)
.equ TERNARY_REG_COUNT, 16   # Number of ternary registers
.equ TERNARY_REG_WIDTH, 32   # Width in bits (16 trits * 2 bits/trit)

# Ternary encoding
.equ TRIT_NEG,         0x00  # -1 (negative)
.equ TRIT_ZERO,        0x01  # 0 (zero)
.equ TRIT_POS,         0x02  # +1 (positive)
.equ TRIT_INVALID,     0x03  # Invalid (not used)

# Common ternary patterns
.equ TERNARY_ALL_NEG,  0x00000000  # All -1
.equ TERNARY_ALL_ZERO, 0x55555555  # All 0
.equ TERNARY_ALL_POS,  0xAAAAAAAA  # All +1
.equ TERNARY_MIX1,     0xAAAA5555  # Mixed pattern 1
.equ TERNARY_MIX2,     0x5555AAAA  # Mixed pattern 2

# MHX™ instruction opcodes (custom extensions)
# Note: These are hypothetical opcodes for the MHX™ ternary extensions
.equ OP_TERNARY,       0x0B  # Ternary arithmetic operations
.equ OP_NEURAL,        0x2B  # Neural processing operations

# Ternary instruction function codes
.equ FUNC_TADD,        0x0   # Ternary addition
.equ FUNC_TSUB,        0x1   # Ternary subtraction
.equ FUNC_TMUL,        0x2   # Ternary multiplication
.equ FUNC_TAND,        0x3   # Ternary AND (min)
.equ FUNC_TOR,         0x4   # Ternary OR (max)
.equ FUNC_TXOR,        0x5   # Ternary XOR
.equ FUNC_TNOT,        0x6   # Ternary NOT (negation)

# Neural instruction function codes
.equ FUNC_NEURON,      0x0   # Neuron operation
.equ FUNC_NEURONA,     0x1   # Neuron accumulate
.equ FUNC_ACTIVATE,    0x2   # Activation function
.equ FUNC_LEARN,       0x3   # Learning update

# ============================================================================
# Assembly Macros
# ============================================================================

# Macro to load a 32-bit immediate value
.macro li32 reg, imm
    lui \reg, %hi(\imm)
    ori \reg, \reg, %lo(\imm)
.endm

# Macro to load address
.macro la_abs reg, addr
    lui \reg, %hi(\addr)
    ori \reg, \reg, %lo(\addr)
.endm

# Macro for UART character output
.macro uart_putc reg
    li32 t6, UART_BASE
1:  lw t5, UART_STATUS(t6)
    andi t5, t5, UART_TX_READY
    beqz t5, 1b
    sw \reg, UART_TX_DATA(t6)
.endm

# Macro for simple delay
.macro delay_cycles count
    li t6, \count
2:  addi t6, t6, -1
    bnez t6, 2b
.endm

# Macro for GPIO output
.macro gpio_write value
    li32 t6, GPIO_BASE
    li t5, \value
    sw t5, GPIO_OUT(t6)
.endm

# ============================================================================
# Documentation References
# ============================================================================

/*
 * Memory Map Summary:
 * 
 * 0x0000_0000 - 0x0000_FFFF : ROM (64KB)
 *   Boot code, program text, read-only data
 * 
 * 0x2000_0000 - 0x2000_FFFF : RAM (64KB)
 *   Runtime data, heap, stack
 * 
 * 0x4000_0000 - 0x4000_0FFF : UART
 *   Serial communication peripheral
 * 
 * 0x4001_0000 - 0x4001_0FFF : GPIO
 *   General purpose I/O (LEDs, buttons)
 * 
 * 0x4002_0000 - 0x4002_0FFF : Timer
 *   System timer with interrupt capability
 * 
 * 0x4003_0000 - 0x4003_0FFF : SPI
 *   Serial Peripheral Interface (optional)
 * 
 * Register Usage Conventions:
 * - t0-t6: Temporary registers (caller-saved)
 * - a0-a7: Argument/return registers
 * - s0-s11: Saved registers (callee-saved)
 * - sp: Stack pointer
 * - ra: Return address
 * 
 * MHX™ Ternary Extensions:
 * - T0-T15: Ternary registers (16 trits each)
 * - Custom instructions for ternary arithmetic
 * - Neural processing operations
 */