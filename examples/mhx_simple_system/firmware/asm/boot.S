# Copyright lowRISC contributors.
# Copyright 2025 MHX Neural.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

/**
 * MHX Simple System Boot Loader
 *
 * This is the entry point for all programs running on the MHX Simple System.
 * It performs basic system initialization and jumps to the main program.
 *
 * Memory Map:
 * - ROM: 0x0000_0000 - 0x0000_FFFF (64KB)
 * - RAM: 0x2000_0000 - 0x2000_FFFF (64KB)
 * - UART: 0x4000_0000
 * - GPIO: 0x4001_0000
 * - Timer: 0x4002_0000
 * - SPI: 0x4003_0000
 */

.section .text.boot
.global _start
.global _boot

# Memory map constants
.equ ROM_BASE,   0x00000000
.equ ROM_SIZE,   0x00010000
.equ RAM_BASE,   0x20000000
.equ RAM_SIZE,   0x00010000
.equ UART_BASE,  0x40000000
.equ GPIO_BASE,  0x40010000
.equ TIMER_BASE, 0x40020000
.equ SPI_BASE,   0x40030000

# Stack configuration
.equ STACK_TOP,  (RAM_BASE + RAM_SIZE)

# Peripheral register offsets
.equ UART_TX_DATA,   0x00
.equ UART_STATUS,    0x04
.equ GPIO_OUT,       0x00
.equ GPIO_OE,        0x04
.equ GPIO_IN,        0x08
.equ TIMER_COUNT,    0x00
.equ TIMER_COMPARE,  0x04
.equ TIMER_CTRL,     0x08

/**
 * Boot entry point
 * This is where the CPU starts execution after reset
 */
_start:
_boot:
    # Disable interrupts during boot
    csrci mstatus, 0x8

    # Set up stack pointer
    li sp, STACK_TOP

    # Set up global pointer (if needed)
    # la gp, __global_pointer$

    # Initialize exception vectors
    la t0, _trap_handler
    csrw mtvec, t0

    # Clear BSS section (if we had one)
    # For now, we don't have a BSS section

    # Initialize data section (if we had one)
    # For now, all data is in ROM or initialized in RAM

    # Initialize peripherals
    call _init_uart
    call _init_gpio
    call _init_timer

    # Print boot message
    call _print_boot_message

    # Enable interrupts
    csrsi mstatus, 0x8

    # Jump to main program
    # For now, just run a simple test
    call _main_program

    # If main returns, loop forever
    j _hang

/**
 * Initialize UART peripheral
 */
_init_uart:
    # UART is already initialized by hardware
    # Just clear any pending status
    li t0, UART_BASE
    li t1, 0
    sw t1, UART_STATUS(t0)
    ret

/**
 * Initialize GPIO peripheral
 */
_init_gpio:
    li t0, GPIO_BASE

    # Set GPIO direction (all outputs for LEDs)
    li t1, 0xFF
    sw t1, GPIO_OE(t0)

    # Clear GPIO outputs
    li t1, 0x00
    sw t1, GPIO_OUT(t0)

    ret

/**
 * Initialize Timer peripheral
 */
_init_timer:
    li t0, TIMER_BASE

    # Set timer compare value (1 second at 100MHz)
    li t1, 100000000
    sw t1, TIMER_COMPARE(t0)

    # Reset timer count
    li t1, 0
    sw t1, TIMER_COUNT(t0)

    # Enable timer
    li t1, 1
    sw t1, TIMER_CTRL(t0)

    ret

/**
 * Print boot message via UART
 */
_print_boot_message:
    # Save return address
    addi sp, sp, -4
    sw ra, 0(sp)

    # Print "MHX Simple System Boot\n"
    la t0, boot_message
    call _print_string

    # Print memory information
    call _print_memory_info

    # Restore return address
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

/**
 * Print memory map information
 */
_print_memory_info:
    addi sp, sp, -4
    sw ra, 0(sp)

    la t0, memory_info_msg
    call _print_string

    lw ra, 0(sp)
    addi sp, sp, 4
    ret

/**
 * Print a null-terminated string via UART
 * Input: t0 = string address
 */
_print_string:
    li t1, UART_BASE

print_loop:
    lb t2, 0(t0)        # Load byte from string
    beqz t2, print_done # If null terminator, done

    # Wait for UART ready (simplified)
    # In real implementation, check status register

    # Send character
    sw t2, UART_TX_DATA(t1)

    # Next character
    addi t0, t0, 1
    j print_loop

print_done:
    ret

/**
 * Main program - can be overridden by linking with different main
 */
_main_program:
    # Save return address
    addi sp, sp, -4
    sw ra, 0(sp)

    # Run GPIO blink test
    call _gpio_blink_test

    # Run ternary test if MHX extensions are available
    call _ternary_demo

    # Restore return address
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

/**
 * Simple GPIO blink test
 */
_gpio_blink_test:
    li t0, GPIO_BASE
    li t1, 1          # LED pattern
    li t2, 8          # Number of blinks

blink_loop:
    # Turn on LED
    sw t1, GPIO_OUT(t0)

    # Simple delay
    li t3, 1000000
delay1:
    addi t3, t3, -1
    bnez t3, delay1

    # Turn off LED
    sw zero, GPIO_OUT(t0)

    # Simple delay
    li t3, 1000000
delay2:
    addi t3, t3, -1
    bnez t3, delay2

    # Next LED
    slli t1, t1, 1
    andi t1, t1, 0xFF

    # Decrement counter
    addi t2, t2, -1
    bnez t2, blink_loop

    ret

/**
 * Ternary extensions demo
 * This demonstrates the MHX ternary instructions
 */
_ternary_demo:
    # Note: These are pseudo-instructions for MHX ternary extensions
    # In real implementation, these would be custom instruction encodings

    # For now, just demonstrate with regular RISC-V instructions
    # showing what ternary operations would look like

    # Load ternary values (simulated)
    li t0, 0xAAAA5555  # Example ternary pattern
    li t1, 0x5555AAAA  # Another ternary pattern

    # Simulate ternary addition (would be TADD instruction)
    add t2, t0, t1

    # Simulate ternary multiplication (would be TMUL instruction)
    mul t3, t0, t1

    # Simulate neural operation (would be NEURON instruction)
    # For now, just use regular multiply-accumulate
    li t4, 0           # Accumulator
    mul t5, t0, t1     # Weight * Input
    add t4, t4, t5     # Accumulate

    ret

/**
 * Exception/Interrupt handler
 */
_trap_handler:
    # Save context (simplified)
    addi sp, sp, -32
    sw t0, 0(sp)
    sw t1, 4(sp)
    sw t2, 8(sp)
    sw ra, 12(sp)

    # Check cause of trap
    csrr t0, mcause

    # Handle timer interrupt
    li t1, 0x80000007  # Timer interrupt cause
    beq t0, t1, _handle_timer_irq

    # Handle external interrupt
    li t1, 0x8000000B  # External interrupt cause
    beq t0, t1, _handle_external_irq

    # Default: print error and hang
    la t0, trap_error_msg
    call _print_string
    j _hang

_handle_timer_irq:
    # Toggle LED on timer interrupt
    li t0, GPIO_BASE
    lw t1, GPIO_OUT(t0)
    xori t1, t1, 0x01
    sw t1, GPIO_OUT(t0)

    # Clear timer interrupt
    li t0, TIMER_BASE
    sw zero, TIMER_COUNT(t0)

    j _trap_exit

_handle_external_irq:
    # Handle UART or other external interrupts
    # For now, just acknowledge
    j _trap_exit

_trap_exit:
    # Restore context
    lw ra, 12(sp)
    lw t2, 8(sp)
    lw t1, 4(sp)
    lw t0, 0(sp)
    addi sp, sp, 32

    # Return from trap
    mret

/**
 * Hang - infinite loop for error conditions
 */
_hang:
    j _hang

# ============================================================================
# Data Section
# ============================================================================

.section .rodata

boot_message:
    .ascii "MHX Simple System Boot v1.0\n"
    .ascii "Copyright 2025 MHX Neural\n"
    .ascii "==========================\n\0"

memory_info_msg:
    .ascii "Memory Map:\n"
    .ascii "  ROM:   0x00000000 - 0x0000FFFF (64KB)\n"
    .ascii "  RAM:   0x20000000 - 0x2000FFFF (64KB)\n"
    .ascii "  UART:  0x40000000\n"
    .ascii "  GPIO:  0x40010000\n"
    .ascii "  Timer: 0x40020000\n"
    .ascii "  SPI:   0x40030000\n"
    .ascii "Starting main program...\n\0"

trap_error_msg:
    .ascii "ERROR: Unhandled trap!\n\0"

# ============================================================================
# Vector Table (if needed)
# ============================================================================

.section .vectors
.align 8

vector_table:
    j _trap_handler  # All vectors point to same handler for now
    j _trap_handler
    j _trap_handler
    j _trap_handler
    j _trap_handler
    j _trap_handler
    j _trap_handler
    j _trap_handler