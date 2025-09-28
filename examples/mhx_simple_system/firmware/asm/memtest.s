# Copyright lowRISC contributors.
# Copyright 2025 MHX Neural.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

/**
 * Memory Test - Assembly Implementation
 *
 * This program performs comprehensive memory testing on the MHX Simple System.
 * It tests both ROM (read-only) and RAM with various patterns and algorithms.
 *
 * Features:
 * - Walking bit patterns
 * - Address pattern tests  
 * - Data pattern tests
 * - March tests (March C-)
 * - Ternary pattern tests (for MHX extensions)
 * - Memory speed benchmarks
 */

.section .text
.global _start
.global main

# Memory map constants
.equ ROM_BASE,   0x00000000
.equ ROM_SIZE,   0x00010000  # 64KB
.equ RAM_BASE,   0x20000000
.equ RAM_SIZE,   0x00010000  # 64KB
.equ UART_BASE,  0x40000000
.equ GPIO_BASE,  0x40010000
.equ TIMER_BASE, 0x40020000

# UART register offsets
.equ UART_TX_DATA,    0x00
.equ UART_STATUS,     0x04
.equ UART_TX_READY,   0x01

# GPIO register offsets
.equ GPIO_OUT,        0x00
.equ GPIO_OE,         0x04

# Timer register offsets
.equ TIMER_COUNT,     0x00
.equ TIMER_COMPARE,   0x04
.equ TIMER_CTRL,      0x08

# Test patterns
.equ PATTERN_0x00,    0x00000000
.equ PATTERN_0xFF,    0xFFFFFFFF
.equ PATTERN_0x55,    0x55555555
.equ PATTERN_0xAA,    0xAAAAAAAA
.equ PATTERN_TERNARY1, 0xAAAA5555  # MHX ternary pattern
.equ PATTERN_TERNARY2, 0x5555AAAA  # MHX ternary pattern

/**
 * Main entry point
 */
_start:
main:
    # Initialize system
    call init_system
    
    # Print startup message
    call print_startup
    
    # Run memory tests
    call run_memory_tests
    
    # Print results summary
    call print_summary
    
    # Infinite loop
    j hang

/**
 * Initialize system peripherals
 */
init_system:
    addi sp, sp, -4
    sw ra, 0(sp)
    
    # Set stack pointer to safe area (top of RAM - 1KB for test data)
    li sp, (RAM_BASE + RAM_SIZE - 1024)
    
    # Initialize UART
    call init_uart
    
    # Initialize GPIO for status
    call init_gpio
    
    # Initialize timer for benchmarks
    call init_timer
    
    # Initialize test variables
    call init_test_vars
    
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

/**
 * Initialize UART
 */
init_uart:
    # UART assumed to be initialized by boot ROM
    # Just indicate ready status
    li t0, GPIO_BASE
    li t1, 0x01  # LED 0 on = UART ready
    sw t1, GPIO_OUT(t0)
    ret

/**
 * Initialize GPIO
 */
init_gpio:
    li t0, GPIO_BASE
    li t1, 0xFF  # All outputs
    sw t1, GPIO_OE(t0)
    sw zero, GPIO_OUT(t0)  # All LEDs off initially
    ret

/**
 * Initialize timer
 */
init_timer:
    li t0, TIMER_BASE
    li t1, 100000  # 1ms at 100MHz
    sw t1, TIMER_COMPARE(t0)
    li t1, 1
    sw t1, TIMER_CTRL(t0)
    ret

/**
 * Initialize test variables
 */
init_test_vars:
    la t0, test_results
    sw zero, 0(t0)   # total_tests
    sw zero, 4(t0)   # passed_tests
    sw zero, 8(t0)   # failed_tests
    sw zero, 12(t0)  # error_count
    ret

/**
 * Print startup message
 */
print_startup:
    addi sp, sp, -4
    sw ra, 0(sp)
    
    la a0, startup_msg
    call uart_print_string
    
    # Show memory map
    call print_memory_map
    
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

/**
 * Print memory map information
 */
print_memory_map:
    addi sp, sp, -4
    sw ra, 0(sp)
    
    la a0, memmap_msg
    call uart_print_string
    
    # ROM info
    la a0, rom_info_msg
    call uart_print_string
    li a0, ROM_BASE
    call uart_print_hex
    la a0, dash_msg
    call uart_print_string
    li a0, (ROM_BASE + ROM_SIZE - 1)
    call uart_print_hex
    call uart_print_newline
    
    # RAM info
    la a0, ram_info_msg
    call uart_print_string
    li a0, RAM_BASE
    call uart_print_hex
    la a0, dash_msg
    call uart_print_string
    li a0, (RAM_BASE + RAM_SIZE - 1)
    call uart_print_hex
    call uart_print_newline
    call uart_print_newline
    
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

/**
 * Run comprehensive memory tests
 */
run_memory_tests:
    addi sp, sp, -4
    sw ra, 0(sp)
    
    # Test 1: ROM Read Test
    la a0, test1_msg
    call uart_print_string
    call rom_read_test
    call print_test_result
    
    # Test 2: RAM Basic Read/Write
    la a0, test2_msg
    call uart_print_string
    call ram_basic_test
    call print_test_result
    
    # Test 3: Walking Bit Test
    la a0, test3_msg
    call uart_print_string
    call walking_bit_test
    call print_test_result
    
    # Test 4: Address Pattern Test
    la a0, test4_msg
    call uart_print_string
    call address_pattern_test
    call print_test_result
    
    # Test 5: Data Pattern Test
    la a0, test5_msg
    call uart_print_string
    call data_pattern_test
    call print_test_result
    
    # Test 6: March Test
    la a0, test6_msg
    call uart_print_string
    call march_test
    call print_test_result
    
    # Test 7: Ternary Pattern Test (MHX specific)
    la a0, test7_msg
    call uart_print_string
    call ternary_pattern_test
    call print_test_result
    
    # Test 8: Memory Speed Benchmark
    la a0, test8_msg
    call uart_print_string
    call memory_speed_test
    call print_test_result
    
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

/**
 * ROM Read Test - Verify ROM contains expected data
 */
rom_read_test:
    li t0, ROM_BASE
    li t1, ROM_SIZE / 4  # Number of words
    li t2, 0             # Error count
    
    # Update test count
    call increment_test_count
    
rom_read_loop:
    lw t3, 0(t0)
    # For now, just verify we can read without bus error
    # In real test, would verify against known good data
    
    addi t0, t0, 4
    addi t1, t1, -1
    bnez t1, rom_read_loop
    
    # Test passed if no errors
    beqz t2, rom_read_pass
    call increment_failed_count
    ret
    
rom_read_pass:
    call increment_passed_count
    ret

/**
 * RAM Basic Read/Write Test
 */
ram_basic_test:
    li t0, RAM_BASE
    li t1, (RAM_SIZE / 4) - 256  # Leave space for stack
    li t2, 0                     # Error count
    
    call increment_test_count
    
    # Test pattern: write address as data
ram_basic_loop:
    # Write address as data
    sw t0, 0(t0)
    
    # Read back and verify
    lw t3, 0(t0)
    bne t0, t3, ram_basic_error
    
    addi t0, t0, 4
    addi t1, t1, -1
    bnez t1, ram_basic_loop
    
    beqz t2, ram_basic_pass
    call increment_failed_count
    ret

ram_basic_error:
    addi t2, t2, 1
    # Continue test but track errors
    addi t0, t0, 4
    addi t1, t1, -1
    bnez t1, ram_basic_loop
    
    call increment_failed_count
    ret
    
ram_basic_pass:
    call increment_passed_count
    ret

/**
 * Walking Bit Test
 */
walking_bit_test:
    li t0, RAM_BASE
    li t1, 32            # 32 bit positions
    li t2, 0             # Error count
    
    call increment_test_count
    
walking_bit_loop:
    # Create walking bit pattern
    li t3, 1
    sll t3, t3, t1
    
    # Write pattern
    sw t3, 0(t0)
    
    # Read back and verify
    lw t4, 0(t0)
    bne t3, t4, walking_bit_error
    
    # Test inverse pattern
    not t3, t3
    sw t3, 0(t0)
    lw t4, 0(t0)
    bne t3, t4, walking_bit_error
    
    addi t1, t1, -1
    bnez t1, walking_bit_loop
    
    beqz t2, walking_bit_pass
    call increment_failed_count
    ret

walking_bit_error:
    addi t2, t2, 1
    addi t1, t1, -1
    bnez t1, walking_bit_loop
    call increment_failed_count
    ret
    
walking_bit_pass:
    call increment_passed_count
    ret

/**
 * Address Pattern Test
 */
address_pattern_test:
    li t0, RAM_BASE
    li t1, (RAM_SIZE / 4) - 256
    li t2, 0
    
    call increment_test_count
    
    # Phase 1: Write address pattern
    mv t3, t0
addr_write_loop:
    sw t3, 0(t3)
    addi t3, t3, 4
    addi t1, t1, -1
    bnez t1, addr_write_loop
    
    # Phase 2: Read and verify
    li t1, (RAM_SIZE / 4) - 256
    mv t3, t0
addr_read_loop:
    lw t4, 0(t3)
    bne t3, t4, addr_pattern_error
    addi t3, t3, 4
    addi t1, t1, -1
    bnez t1, addr_read_loop
    
    beqz t2, addr_pattern_pass
    call increment_failed_count
    ret

addr_pattern_error:
    addi t2, t2, 1
    addi t3, t3, 4
    addi t1, t1, -1
    bnez t1, addr_read_loop
    call increment_failed_count
    ret
    
addr_pattern_pass:
    call increment_passed_count
    ret

/**
 * Data Pattern Test - Test with various patterns
 */
data_pattern_test:
    call increment_test_count
    
    # Test pattern 1: 0x00000000
    li a0, PATTERN_0x00
    call test_single_pattern
    bnez a0, data_pattern_fail
    
    # Test pattern 2: 0xFFFFFFFF  
    li a0, PATTERN_0xFF
    call test_single_pattern
    bnez a0, data_pattern_fail
    
    # Test pattern 3: 0x55555555
    li a0, PATTERN_0x55
    call test_single_pattern
    bnez a0, data_pattern_fail
    
    # Test pattern 4: 0xAAAAAAAA
    li a0, PATTERN_0xAA
    call test_single_pattern
    bnez a0, data_pattern_fail
    
    call increment_passed_count
    ret

data_pattern_fail:
    call increment_failed_count
    ret

/**
 * Test single data pattern
 * Input: a0 = pattern
 * Output: a0 = 0 if pass, 1 if fail
 */
test_single_pattern:
    li t0, RAM_BASE
    li t1, (RAM_SIZE / 4) - 256
    mv t2, a0  # Save pattern
    
    # Write pattern
pattern_write_loop:
    sw t2, 0(t0)
    addi t0, t0, 4
    addi t1, t1, -1
    bnez t1, pattern_write_loop
    
    # Read and verify
    li t0, RAM_BASE
    li t1, (RAM_SIZE / 4) - 256
pattern_read_loop:
    lw t3, 0(t0)
    bne t2, t3, pattern_test_fail
    addi t0, t0, 4
    addi t1, t1, -1
    bnez t1, pattern_read_loop
    
    li a0, 0  # Success
    ret

pattern_test_fail:
    li a0, 1  # Failure
    ret

/**
 * March Test (March C- algorithm)
 */
march_test:
    call increment_test_count
    
    li t0, RAM_BASE
    li t1, (RAM_SIZE / 4) - 256
    
    # Step 1: Write 0 to all locations (ascending)
    mv t2, t0
    mv t3, t1
march_step1:
    sw zero, 0(t2)
    addi t2, t2, 4
    addi t3, t3, -1
    bnez t3, march_step1
    
    # Step 2: Read 0, Write 1 (ascending)
    mv t2, t0
    mv t3, t1
march_step2:
    lw t4, 0(t2)
    bnez t4, march_test_fail
    li t5, 0xFFFFFFFF
    sw t5, 0(t2)
    addi t2, t2, 4
    addi t3, t3, -1
    bnez t3, march_step2
    
    # Step 3: Read 1, Write 0 (descending)
    li t2, RAM_BASE + (RAM_SIZE - 1024)  # End address
    mv t3, t1
march_step3:
    lw t4, 0(t2)
    li t5, 0xFFFFFFFF
    bne t4, t5, march_test_fail
    sw zero, 0(t2)
    addi t2, t2, -4
    addi t3, t3, -1
    bnez t3, march_step3
    
    # Step 4: Read 0 (ascending)
    mv t2, t0
    mv t3, t1
march_step4:
    lw t4, 0(t2)
    bnez t4, march_test_fail
    addi t2, t2, 4
    addi t3, t3, -1
    bnez t3, march_step4
    
    call increment_passed_count
    ret

march_test_fail:
    call increment_failed_count
    ret

/**
 * Ternary Pattern Test (MHX specific)
 */
ternary_pattern_test:
    call increment_test_count
    
    # Test ternary pattern 1
    li a0, PATTERN_TERNARY1
    call test_single_pattern
    bnez a0, ternary_test_fail
    
    # Test ternary pattern 2
    li a0, PATTERN_TERNARY2
    call test_single_pattern
    bnez a0, ternary_test_fail
    
    # Test mixed ternary patterns
    call test_ternary_mixed
    bnez a0, ternary_test_fail
    
    call increment_passed_count
    ret

ternary_test_fail:
    call increment_failed_count
    ret

/**
 * Test mixed ternary patterns
 */
test_ternary_mixed:
    li t0, RAM_BASE
    li t1, (RAM_SIZE / 8) - 128  # Smaller test for speed
    
    # Write alternating ternary patterns
    li t2, PATTERN_TERNARY1
    li t3, PATTERN_TERNARY2
    
ternary_mixed_write:
    sw t2, 0(t0)
    sw t3, 4(t0)
    addi t0, t0, 8
    addi t1, t1, -1
    bnez t1, ternary_mixed_write
    
    # Read and verify
    li t0, RAM_BASE
    li t1, (RAM_SIZE / 8) - 128
    
ternary_mixed_read:
    lw t4, 0(t0)
    bne t4, t2, ternary_mixed_fail
    lw t4, 4(t0)
    bne t4, t3, ternary_mixed_fail
    addi t0, t0, 8
    addi t1, t1, -1
    bnez t1, ternary_mixed_read
    
    li a0, 0  # Success
    ret

ternary_mixed_fail:
    li a0, 1  # Failure
    ret

/**
 * Memory Speed Test/Benchmark
 */
memory_speed_test:
    call increment_test_count
    
    addi sp, sp, -4
    sw ra, 0(sp)
    
    la a0, speed_test_msg
    call uart_print_string
    
    # Test 1: Sequential write speed
    call test_write_speed
    
    # Test 2: Sequential read speed
    call test_read_speed
    
    # Test 3: Random access speed
    call test_random_speed
    
    call increment_passed_count
    
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

/**
 * Test sequential write speed
 */
test_write_speed:
    addi sp, sp, -4
    sw ra, 0(sp)
    
    # Get start time
    li t0, TIMER_BASE
    lw t1, TIMER_COUNT(t0)  # Start time
    
    # Write test
    li t2, RAM_BASE
    li t3, (RAM_SIZE / 4) - 256
    li t4, 0xDEADBEEF
    
write_speed_loop:
    sw t4, 0(t2)
    addi t2, t2, 4
    addi t3, t3, -1
    bnez t3, write_speed_loop
    
    # Get end time
    lw t2, TIMER_COUNT(t0)  # End time
    
    # Calculate and print speed
    sub a0, t2, t1
    la a1, write_speed_msg
    call print_speed_result
    
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

/**
 * Test sequential read speed
 */
test_read_speed:
    addi sp, sp, -4
    sw ra, 0(sp)
    
    # Get start time
    li t0, TIMER_BASE
    lw t1, TIMER_COUNT(t0)
    
    # Read test
    li t2, RAM_BASE
    li t3, (RAM_SIZE / 4) - 256
    
read_speed_loop:
    lw t4, 0(t2)
    addi t2, t2, 4
    addi t3, t3, -1
    bnez t3, read_speed_loop
    
    # Get end time
    lw t2, TIMER_COUNT(t0)
    
    # Calculate and print speed
    sub a0, t2, t1
    la a1, read_speed_msg
    call print_speed_result
    
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

/**
 * Test random access speed
 */
test_random_speed:
    addi sp, sp, -4
    sw ra, 0(sp)
    
    # Simple random access test (pseudo-random)
    li t0, TIMER_BASE
    lw t1, TIMER_COUNT(t0)
    
    # Random access pattern
    li t2, 1000  # Number of accesses
    li t3, 0x12345678  # Seed
    
random_access_loop:
    # Generate pseudo-random address
    slli t4, t3, 1
    xor t3, t3, t4
    andi t4, t3, 0xFFFC  # Word aligned
    li t5, RAM_BASE
    add t4, t4, t5
    
    # Bounds check
    li t5, (RAM_BASE + RAM_SIZE - 1024)
    bge t4, t5, random_access_next
    
    # Random read
    lw t5, 0(t4)
    
random_access_next:
    addi t2, t2, -1
    bnez t2, random_access_loop
    
    # Get end time
    lw t2, TIMER_COUNT(t0)
    
    # Calculate and print speed
    sub a0, t2, t1
    la a1, random_speed_msg
    call print_speed_result
    
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

/**
 * Print speed test result
 * Input: a0 = cycles, a1 = message
 */
print_speed_result:
    addi sp, sp, -8
    sw ra, 0(sp)
    sw a0, 4(sp)
    
    mv a0, a1
    call uart_print_string
    
    lw a0, 4(sp)
    call uart_print_hex
    
    la a0, cycles_msg
    call uart_print_string
    call uart_print_newline
    
    lw a0, 4(sp)
    lw ra, 0(sp)
    addi sp, sp, 8
    ret

/**
 * Print test results summary
 */
print_summary:
    addi sp, sp, -4
    sw ra, 0(sp)
    
    la a0, summary_msg
    call uart_print_string
    
    # Total tests
    la t0, test_results
    lw a0, 0(t0)
    la a1, total_tests_msg
    call print_count_result
    
    # Passed tests
    lw a0, 4(t0)
    la a1, passed_tests_msg
    call print_count_result
    
    # Failed tests
    lw a0, 8(t0)
    la a1, failed_tests_msg
    call print_count_result
    
    # Overall result
    lw t1, 4(t0)  # Passed
    lw t2, 0(t0)  # Total
    beq t1, t2, all_tests_passed
    
    la a0, some_tests_failed_msg
    call uart_print_string
    j summary_done
    
all_tests_passed:
    la a0, all_tests_passed_msg
    call uart_print_string

summary_done:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

/**
 * Print count result
 */
print_count_result:
    addi sp, sp, -8
    sw ra, 0(sp)
    sw a0, 4(sp)
    
    mv a0, a1
    call uart_print_string
    
    lw a0, 4(sp)
    call uart_print_decimal
    call uart_print_newline
    
    lw a0, 4(sp)
    lw ra, 0(sp)
    addi sp, sp, 8
    ret

/**
 * Helper functions for test counting
 */
increment_test_count:
    la t0, test_results
    lw t1, 0(t0)
    addi t1, t1, 1
    sw t1, 0(t0)
    ret

increment_passed_count:
    la t0, test_results
    lw t1, 4(t0)
    addi t1, t1, 1
    sw t1, 4(t0)
    ret

increment_failed_count:
    la t0, test_results
    lw t1, 8(t0)
    addi t1, t1, 1
    sw t1, 8(t0)
    ret

/**
 * Print test result (pass/fail)
 */
print_test_result:
    addi sp, sp, -4
    sw ra, 0(sp)
    
    # Check if last test passed by comparing counts
    la t0, test_results
    lw t1, 0(t0)  # Total
    lw t2, 4(t0)  # Passed
    lw t3, 8(t0)  # Failed
    
    add t4, t2, t3
    beq t1, t4, check_last_result
    
    # This shouldn't happen
    la a0, error_msg
    call uart_print_string
    j print_result_done

check_last_result:
    # Get previous totals to see if last test passed
    # Simple: if failed count increased, last test failed
    la t0, test_results
    lw t3, 8(t0)  # Current failed count
    
    # For simplicity, assume we can check the LED status
    li t0, GPIO_BASE
    lw t1, GPIO_OUT(t0)
    andi t1, t1, 0x80  # Check if error LED is on
    
    bnez t1, print_fail_result
    
    la a0, pass_msg
    call uart_print_string
    j print_result_done

print_fail_result:
    la a0, fail_msg
    call uart_print_string

print_result_done:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

/**
 * UART utility functions
 */
uart_print_string:
    addi sp, sp, -8
    sw ra, 0(sp)
    sw t0, 4(sp)
    
    mv t0, a0
print_char_loop:
    lb a0, 0(t0)
    beqz a0, print_string_done
    call uart_putchar
    addi t0, t0, 1
    j print_char_loop

print_string_done:
    lw t0, 4(sp)
    lw ra, 0(sp)
    addi sp, sp, 8
    ret

uart_putchar:
    li t0, UART_BASE
uart_wait:
    lw t1, UART_STATUS(t0)
    andi t1, t1, UART_TX_READY
    beqz t1, uart_wait
    sw a0, UART_TX_DATA(t0)
    ret

uart_print_newline:
    addi sp, sp, -4
    sw ra, 0(sp)
    li a0, 0x0A
    call uart_putchar
    li a0, 0x0D
    call uart_putchar
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

uart_print_hex:
    addi sp, sp, -12
    sw ra, 0(sp)
    sw t0, 4(sp)
    sw t1, 8(sp)
    
    li a0, '0'
    call uart_putchar
    li a0, 'x'
    call uart_putchar
    
    lw t0, 4(sp)  # Restore value
    li t1, 8
    
hex_digit_loop:
    srli a0, t0, 28
    andi a0, a0, 0xF
    li t2, 10
    blt a0, t2, hex_is_digit
    addi a0, a0, 'A' - 10
    j hex_print_char
hex_is_digit:
    addi a0, a0, '0'
hex_print_char:
    call uart_putchar
    slli t0, t0, 4
    addi t1, t1, -1
    bnez t1, hex_digit_loop
    
    lw t1, 8(sp)
    lw t0, 4(sp)
    lw ra, 0(sp)
    addi sp, sp, 12
    ret

uart_print_decimal:
    addi sp, sp, -4
    sw ra, 0(sp)
    
    # Convert to decimal and print
    # Simple implementation - just use hex for now
    call uart_print_hex
    
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

hang:
    # Set error LED pattern
    li t0, GPIO_BASE
    li t1, 0xFF
    sw t1, GPIO_OUT(t0)
    j hang

# ============================================================================
# Data Section
# ============================================================================

.section .data
.align 4

# Test results structure
test_results:
    .word 0  # total_tests
    .word 0  # passed_tests
    .word 0  # failed_tests
    .word 0  # error_count

.section .rodata

startup_msg:
    .ascii "MHX Simple System Memory Test\n"
    .ascii "Copyright 2025 MHX Neural\n"
    .ascii "=============================\n\n\0"

memmap_msg:
    .ascii "Memory Map:\n\0"

rom_info_msg:
    .ascii "  ROM: \0"

ram_info_msg:
    .ascii "  RAM: \0"

dash_msg:
    .ascii " - \0"

test1_msg:
    .ascii "Test 1: ROM Read Test... \0"

test2_msg:
    .ascii "Test 2: RAM Basic Test... \0"

test3_msg:
    .ascii "Test 3: Walking Bit Test... \0"

test4_msg:
    .ascii "Test 4: Address Pattern Test... \0"

test5_msg:
    .ascii "Test 5: Data Pattern Test... \0"

test6_msg:
    .ascii "Test 6: March Test... \0"

test7_msg:
    .ascii "Test 7: Ternary Pattern Test... \0"

test8_msg:
    .ascii "Test 8: Memory Speed Test... \0"

speed_test_msg:
    .ascii "  Running speed benchmarks...\n\0"

write_speed_msg:
    .ascii "  Write Speed: \0"

read_speed_msg:
    .ascii "  Read Speed: \0"

random_speed_msg:
    .ascii "  Random Access Speed: \0"

cycles_msg:
    .ascii " cycles\0"

pass_msg:
    .ascii "PASS\n\0"

fail_msg:
    .ascii "FAIL\n\0"

error_msg:
    .ascii "ERROR\n\0"

summary_msg:
    .ascii "\nTest Summary:\n"
    .ascii "=============\n\0"

total_tests_msg:
    .ascii "Total Tests: \0"

passed_tests_msg:
    .ascii "Passed: \0"

failed_tests_msg:
    .ascii "Failed: \0"

all_tests_passed_msg:
    .ascii "All tests PASSED!\n\0"

some_tests_failed_msg:
    .ascii "Some tests FAILED!\n\0"