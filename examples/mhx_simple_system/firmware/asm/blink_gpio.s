# Copyright lowRISC contributors.
# Copyright 2025 MHX™ Neural.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

/**
 * GPIO Blink Test - Assembly Implementation
 *
 * This program demonstrates basic GPIO functionality by blinking LEDs
 * in various patterns. It's designed to run on the MHX™ Simple System.
 *
 * Features:
 * - Multiple LED blink patterns
 * - Timer-based delays
 * - GPIO input monitoring
 * - Simple demonstration of MHX™ system peripherals
 */

.section .text
.global _start
.global main

# Include memory map definitions
.include "memory_map.inc"

/**
 * Main entry point
 */
_start:
main:
    # Initialize system
    call init_system

    # Print startup message
    call print_startup_msg

    # Run GPIO tests
    call run_gpio_tests

    # Main loop
    call main_loop

    # Should never reach here
    j hang

/**
 * Initialize system peripherals
 */
init_system:
    # Save return address
    addi sp, sp, -4
    sw ra, 0(sp)

    # Initialize GPIO
    call init_gpio

    # Initialize timer for delays
    call init_timer

    # Initialize UART for debug output
    call init_uart

    # Restore return address
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

/**
 * Initialize GPIO peripheral
 */
init_gpio:
    li t0, GPIO_BASE

    # Set all pins as outputs (for LEDs)
    li t1, 0xFF
    sw t1, GPIO_OE(t0)

    # Clear all outputs initially
    li t1, 0x00
    sw t1, GPIO_OUT(t0)

    ret

/**
 * Initialize timer for delays
 */
init_timer:
    li t0, TIMER_BASE

    # Set timer compare value for 1ms ticks (100MHz / 1000)
    li t1, 100000
    sw t1, TIMER_COMPARE(t0)

    # Reset counter
    li t1, 0
    sw t1, TIMER_COUNT(t0)

    # Enable timer
    li t1, 1
    sw t1, TIMER_CTRL(t0)

    ret

/**
 * Initialize UART for debug output
 */
init_uart:
    # UART is initialized by hardware
    # Nothing to do here for simple implementation
    ret

/**
 * Print startup message
 */
print_startup_msg:
    addi sp, sp, -4
    sw ra, 0(sp)

    la a0, startup_msg
    call print_string

    lw ra, 0(sp)
    addi sp, sp, 4
    ret

/**
 * Run comprehensive GPIO tests
 */
run_gpio_tests:
    addi sp, sp, -4
    sw ra, 0(sp)

    # Test 1: Simple on/off test
    la a0, test1_msg
    call print_string
    call test_simple_blink

    # Test 2: Walking LED pattern
    la a0, test2_msg
    call print_string
    call test_walking_led

    # Test 3: Binary counter pattern
    la a0, test3_msg
    call print_string
    call test_binary_counter

    # Test 4: Breathing pattern
    la a0, test4_msg
    call print_string
    call test_breathing_pattern

    # Test 5: Input monitoring
    la a0, test5_msg
    call print_string
    call test_input_monitoring

    lw ra, 0(sp)
    addi sp, sp, 4
    ret

/**
 * Test 1: Simple blink all LEDs on/off
 */
test_simple_blink:
    li t0, GPIO_BASE
    li t1, 10         # Number of blinks

simple_blink_loop:
    # Turn all LEDs on
    li t2, 0xFF
    sw t2, GPIO_OUT(t0)

    # Delay 500ms
    li a0, 500
    call delay_ms

    # Turn all LEDs off
    li t2, 0x00
    sw t2, GPIO_OUT(t0)

    # Delay 500ms
    li a0, 500
    call delay_ms

    # Decrement counter
    addi t1, t1, -1
    bnez t1, simple_blink_loop

    ret

/**
 * Test 2: Walking LED pattern (Knight Rider style)
 */
test_walking_led:
    li t0, GPIO_BASE
    li t1, 5          # Number of complete cycles

walking_cycle:
    # Walk left to right
    li t2, 0x01       # Start with LED 0
    li t3, 8          # Number of LEDs

walk_right:
    sw t2, GPIO_OUT(t0)

    li a0, 200
    call delay_ms

    slli t2, t2, 1    # Shift left
    addi t3, t3, -1
    bnez t3, walk_right

    # Walk right to left
    li t2, 0x80       # Start with LED 7
    li t3, 8          # Number of LEDs

walk_left:
    sw t2, GPIO_OUT(t0)

    li a0, 200
    call delay_ms

    srli t2, t2, 1    # Shift right
    addi t3, t3, -1
    bnez t3, walk_left

    addi t1, t1, -1
    bnez t1, walking_cycle

    # Clear LEDs
    sw zero, GPIO_OUT(t0)
    ret

/**
 * Test 3: Binary counter pattern
 */
test_binary_counter:
    li t0, GPIO_BASE
    li t1, 0          # Counter value
    li t2, 256        # Count to 255

counter_loop:
    # Display counter value on LEDs
    sw t1, GPIO_OUT(t0)

    # Delay 100ms
    li a0, 100
    call delay_ms

    # Increment counter
    addi t1, t1, 1
    andi t1, t1, 0xFF # Keep in 8-bit range

    addi t2, t2, -1
    bnez t2, counter_loop

    # Clear LEDs
    sw zero, GPIO_OUT(t0)
    ret

/**
 * Test 4: Breathing pattern (PWM simulation)
 */
test_breathing_pattern:
    li t0, GPIO_BASE
    li t1, 3          # Number of breathing cycles

breathing_cycle:
    # Fade in
    li t2, 0          # Brightness level
    li t3, 32         # Max brightness

fade_in:
    # Simple PWM simulation
    li t4, 100        # PWM period

pwm_period:
    # LED on time proportional to brightness
    sw zero, GPIO_OUT(t0)
    mv a0, t2
    call delay_ms

    # LED off time
    li t5, 0xFF
    sw t5, GPIO_OUT(t0)
    sub a0, t3, t2
    call delay_ms

    addi t4, t4, -1
    bnez t4, pwm_period

    addi t2, t2, 1
    ble t2, t3, fade_in

    # Fade out
    li t2, 32         # Start from max brightness

fade_out:
    # Simple PWM simulation
    li t4, 100        # PWM period

pwm_period2:
    # LED on time proportional to brightness
    sw zero, GPIO_OUT(t0)
    mv a0, t2
    call delay_ms

    # LED off time
    li t5, 0xFF
    sw t5, GPIO_OUT(t0)
    sub a0, t3, t2
    call delay_ms

    addi t4, t4, -1
    bnez t4, pwm_period2

    addi t2, t2, -1
    bgez t2, fade_out

    addi t1, t1, -1
    bnez t1, breathing_cycle

    # Clear LEDs
    sw zero, GPIO_OUT(t0)
    ret

/**
 * Test 5: Input monitoring (echo inputs to outputs)
 */
test_input_monitoring:
    li t0, GPIO_BASE
    li t1, 1000       # Monitor for 1000 iterations

    # Configure GPIO: lower 4 bits as inputs, upper 4 bits as outputs
    li t2, 0xF0
    sw t2, GPIO_OE(t0)

monitor_loop:
    # Read inputs
    lw t2, GPIO_IN(t0)
    andi t2, t2, 0x0F # Mask to lower 4 bits

    # Shift inputs to upper 4 bits for output LEDs
    slli t2, t2, 4

    # Write to outputs
    sw t2, GPIO_OUT(t0)

    # Small delay
    li a0, 10
    call delay_ms

    addi t1, t1, -1
    bnez t1, monitor_loop

    # Restore GPIO to all outputs
    li t2, 0xFF
    sw t2, GPIO_OE(t0)
    sw zero, GPIO_OUT(t0)

    ret

/**
 * Main program loop
 */
main_loop:
    # Continuous GPIO demo
    call run_gpio_tests

    # Add some delay between test cycles
    li a0, 2000
    call delay_ms

    j main_loop

/**
 * Delay function using timer
 * Input: a0 = delay in milliseconds
 */
delay_ms:
    # Save registers
    addi sp, sp, -12
    sw t0, 0(sp)
    sw t1, 4(sp)
    sw t2, 8(sp)

    li t0, TIMER_BASE

    # Get current timer count
    lw t1, TIMER_COUNT(t0)

    # Calculate target count (ms * 100 for 100kHz timer)
    li t2, 100
    mul t2, a0, t2
    add t2, t1, t2

delay_loop:
    lw t1, TIMER_COUNT(t0)
    bltu t1, t2, delay_loop

    # Restore registers
    lw t2, 8(sp)
    lw t1, 4(sp)
    lw t0, 0(sp)
    addi sp, sp, 12
    ret

/**
 * Print string via UART
 * Input: a0 = string address
 */
print_string:
    # Save registers
    addi sp, sp, -8
    sw t0, 0(sp)
    sw t1, 4(sp)

    li t0, UART_BASE
    mv t1, a0

print_loop:
    lb t2, 0(t1)
    beqz t2, print_done

    # Send character (simplified - no flow control)
    sw t2, UART_TX_DATA(t0)

    # Small delay to allow UART transmission
    li a0, 1
    call delay_ms

    addi t1, t1, 1
    j print_loop

print_done:
    # Restore registers
    lw t1, 4(sp)
    lw t0, 0(sp)
    addi sp, sp, 8
    ret

/**
 * Hang function for error conditions
 */
hang:
    j hang

# ============================================================================
# Include memory map definitions
# ============================================================================

.section .rodata

# Memory map constants (duplicated from boot.S for standalone compilation)
.equ ROM_BASE,   0x00000000
.equ ROM_SIZE,   0x00010000
.equ RAM_BASE,   0x20000000
.equ RAM_SIZE,   0x00010000
.equ UART_BASE,  0x40000000
.equ GPIO_BASE,  0x40010000
.equ TIMER_BASE, 0x40020000
.equ SPI_BASE,   0x40030000

# Peripheral register offsets
.equ UART_TX_DATA,   0x00
.equ UART_STATUS,    0x04
.equ GPIO_OUT,       0x00
.equ GPIO_OE,        0x04
.equ GPIO_IN,        0x08
.equ TIMER_COUNT,    0x00
.equ TIMER_COMPARE,  0x04
.equ TIMER_CTRL,     0x08

# ============================================================================
# String constants
# ============================================================================

startup_msg:
    .ascii "MHX™ GPIO Blink Test Starting...\n\0"

test1_msg:
    .ascii "Test 1: Simple blink\n\0"

test2_msg:
    .ascii "Test 2: Walking LED\n\0"

test3_msg:
    .ascii "Test 3: Binary counter\n\0"

test4_msg:
    .ascii "Test 4: Breathing pattern\n\0"

test5_msg:
    .ascii "Test 5: Input monitoring\n\0"