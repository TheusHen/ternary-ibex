# Copyright lowRISC contributors.
# Copyright 2025 MHX Neural.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

/**
 * UART Echo Test - Assembly Implementation
 *
 * This program demonstrates UART functionality by echoing received characters
 * back to the sender with some processing and formatting.
 *
 * Features:
 * - Character echo with case conversion
 * - Command processing  
 * - Status reporting
 * - Simple line editing
 * - Demonstration of UART interrupts
 */

.section .text
.global _start
.global main

# Memory map constants
.equ ROM_BASE,   0x00000000
.equ RAM_BASE,   0x20000000  
.equ UART_BASE,  0x40000000
.equ GPIO_BASE,  0x40010000
.equ TIMER_BASE, 0x40020000

# UART register offsets
.equ UART_TX_DATA,    0x00
.equ UART_RX_DATA,    0x00
.equ UART_STATUS,     0x04
.equ UART_CONTROL,    0x08
.equ UART_BAUD_DIV,   0x0C

# UART status bits
.equ UART_TX_READY,   0x01
.equ UART_RX_READY,   0x02
.equ UART_TX_EMPTY,   0x04
.equ UART_RX_FULL,    0x08

# GPIO register offsets  
.equ GPIO_OUT,        0x00
.equ GPIO_OE,         0x04
.equ GPIO_IN,         0x08

# Timer register offsets
.equ TIMER_COUNT,     0x00
.equ TIMER_COMPARE,   0x04
.equ TIMER_CTRL,      0x08

# Control characters
.equ CHAR_CR,         0x0D
.equ CHAR_LF,         0x0A
.equ CHAR_BS,         0x08
.equ CHAR_DEL,        0x7F
.equ CHAR_ESC,        0x1B
.equ CHAR_SPACE,      0x20

/**
 * Main entry point
 */
_start:
main:
    # Initialize system
    call init_system
    
    # Print welcome message
    call print_welcome
    
    # Main UART echo loop
    call uart_echo_loop
    
    # Should never reach here
    j hang

/**
 * Initialize system peripherals
 */
init_system:
    addi sp, sp, -4
    sw ra, 0(sp)
    
    # Set up stack pointer if not already done
    li sp, (RAM_BASE + 0x10000) # 64KB RAM
    
    # Initialize UART
    call init_uart
    
    # Initialize GPIO for status LEDs
    call init_gpio
    
    # Initialize timer for timeouts
    call init_timer
    
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

/**
 * Initialize UART with proper baud rate and settings
 */
init_uart:
    li t0, UART_BASE
    
    # Set baud rate divisor for 115200 baud at 100MHz
    # Divisor = 100MHz / (16 * 115200) = ~54
    li t1, 54
    sw t1, UART_BAUD_DIV(t0)
    
    # Enable UART TX and RX
    li t1, 0x03  # Enable TX and RX
    sw t1, UART_CONTROL(t0)
    
    # Clear status
    sw zero, UART_STATUS(t0)
    
    ret

/**
 * Initialize GPIO for status indication
 */
init_gpio:
    li t0, GPIO_BASE
    
    # Set all pins as outputs
    li t1, 0xFF
    sw t1, GPIO_OE(t0)
    
    # Initial pattern - show system ready
    li t1, 0x01
    sw t1, GPIO_OUT(t0)
    
    ret

/**
 * Initialize timer for timeouts and delays
 */
init_timer:
    li t0, TIMER_BASE
    
    # Set compare value for 1ms ticks
    li t1, 100000  # 100MHz / 1000
    sw t1, TIMER_COMPARE(t0)
    
    # Enable timer
    li t1, 1
    sw t1, TIMER_CTRL(t0)
    
    ret

/**
 * Print welcome message
 */
print_welcome:
    addi sp, sp, -4
    sw ra, 0(sp)
    
    la a0, welcome_msg
    call uart_print_string
    
    la a0, help_msg
    call uart_print_string
    
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

/**
 * Main UART echo loop
 */
uart_echo_loop:
    # Initialize command buffer
    la t0, cmd_buffer
    li t1, 0
    sw t1, cmd_length
    
    # Show prompt
    la a0, prompt_msg
    call uart_print_string
    
echo_char_loop:
    # Wait for character
    call uart_getchar
    mv t2, a0  # Save received character
    
    # Update activity LED
    call update_activity_led
    
    # Check for special characters
    li t0, CHAR_CR
    beq t2, t0, handle_enter
    
    li t0, CHAR_LF
    beq t2, t0, handle_enter
    
    li t0, CHAR_BS
    beq t2, t0, handle_backspace
    
    li t0, CHAR_DEL
    beq t2, t0, handle_backspace
    
    li t0, CHAR_ESC
    beq t2, t0, handle_escape
    
    # Regular character - add to buffer and echo
    call add_char_to_buffer
    call echo_character
    
    j echo_char_loop

handle_enter:
    # Process command
    call uart_print_newline
    call process_command
    
    # Reset buffer
    sw zero, cmd_length
    
    # Show new prompt
    la a0, prompt_msg
    call uart_print_string
    
    j echo_char_loop

handle_backspace:
    call handle_backspace_char
    j echo_char_loop

handle_escape:
    # Handle escape sequences (future enhancement)
    call echo_character
    j echo_char_loop

/**
 * Add character to command buffer
 * Input: t2 = character
 */
add_char_to_buffer:
    lw t0, cmd_length
    li t1, CMD_BUFFER_SIZE - 1
    bge t0, t1, buffer_full
    
    # Add character to buffer
    la t1, cmd_buffer
    add t1, t1, t0
    sb t2, 0(t1)
    
    # Increment length
    addi t0, t0, 1
    sw t0, cmd_length
    
    ret

buffer_full:
    # Buffer full - ignore character and beep
    li a0, 0x07  # Bell character
    call uart_putchar
    ret

/**
 * Handle backspace character
 */
handle_backspace_char:
    lw t0, cmd_length
    beqz t0, backspace_done  # Nothing to delete
    
    # Remove character from buffer
    addi t0, t0, -1
    sw t0, cmd_length
    
    # Echo backspace sequence
    li a0, CHAR_BS
    call uart_putchar
    li a0, CHAR_SPACE
    call uart_putchar
    li a0, CHAR_BS
    call uart_putchar

backspace_done:
    ret

/**
 * Echo character with case conversion
 * Input: t2 = character
 */
echo_character:
    # Check if lowercase letter
    li t0, 'a'
    blt t2, t0, not_lowercase
    li t0, 'z'
    bgt t2, t0, not_lowercase
    
    # Convert to uppercase
    addi t2, t2, -32

not_lowercase:
    # Check if uppercase letter  
    li t0, 'A'
    blt t2, t0, echo_as_is
    li t0, 'Z'
    bgt t2, t0, echo_as_is
    
    # Convert to lowercase
    addi t2, t2, 32

echo_as_is:
    mv a0, t2
    call uart_putchar
    ret

/**
 * Process command in buffer
 */
process_command:
    addi sp, sp, -4
    sw ra, 0(sp)
    
    # Check command length
    lw t0, cmd_length
    beqz t0, cmd_empty
    
    # Null-terminate command
    la t1, cmd_buffer
    add t1, t1, t0
    sb zero, 0(t1)
    
    # Check for built-in commands
    la a0, cmd_buffer
    la a1, cmd_help
    call string_compare
    beqz a0, cmd_show_help
    
    la a0, cmd_buffer
    la a1, cmd_status
    call string_compare
    beqz a0, cmd_show_status
    
    la a0, cmd_buffer
    la a1, cmd_test
    call string_compare
    beqz a0, cmd_run_test
    
    la a0, cmd_buffer
    la a1, cmd_reset
    call string_compare
    beqz a0, cmd_do_reset
    
    # Unknown command
    la a0, unknown_cmd_msg
    call uart_print_string
    j cmd_done

cmd_empty:
    j cmd_done

cmd_show_help:
    la a0, help_msg
    call uart_print_string
    j cmd_done

cmd_show_status:
    call show_system_status
    j cmd_done

cmd_run_test:
    call run_uart_test
    j cmd_done

cmd_do_reset:
    la a0, reset_msg
    call uart_print_string
    # Perform software reset (jump to start)
    j _start

cmd_done:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

/**
 * Show system status
 */
show_system_status:
    addi sp, sp, -4
    sw ra, 0(sp)
    
    la a0, status_msg
    call uart_print_string
    
    # Show UART status
    li t0, UART_BASE
    lw t1, UART_STATUS(t0)
    la a0, uart_status_msg
    call uart_print_string
    mv a0, t1
    call uart_print_hex
    call uart_print_newline
    
    # Show GPIO status
    li t0, GPIO_BASE
    lw t1, GPIO_OUT(t0)
    la a0, gpio_status_msg
    call uart_print_string
    mv a0, t1
    call uart_print_hex
    call uart_print_newline
    
    # Show timer status
    li t0, TIMER_BASE
    lw t1, TIMER_COUNT(t0)
    la a0, timer_status_msg
    call uart_print_string
    mv a0, t1
    call uart_print_hex
    call uart_print_newline
    
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

/**
 * Run UART loopback test
 */
run_uart_test:
    addi sp, sp, -4
    sw ra, 0(sp)
    
    la a0, test_start_msg
    call uart_print_string
    
    # Send test pattern
    la t0, test_pattern
    li t1, 26  # Alphabet length
    
test_loop:
    lb a0, 0(t0)
    call uart_putchar
    
    # Small delay
    li a0, 10
    call delay_ms
    
    addi t0, t0, 1
    addi t1, t1, -1
    bnez t1, test_loop
    
    call uart_print_newline
    
    la a0, test_done_msg
    call uart_print_string
    
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

/**
 * Update activity LED to show UART activity
 */
update_activity_led:
    li t0, GPIO_BASE
    lw t1, GPIO_OUT(t0)
    
    # Toggle bit 0 to show activity
    xori t1, t1, 0x01
    sw t1, GPIO_OUT(t0)
    
    ret

/**
 * Wait for character from UART
 * Output: a0 = received character
 */
uart_getchar:
    li t0, UART_BASE
    
uart_wait_rx:
    lw t1, UART_STATUS(t0)
    andi t1, t1, UART_RX_READY
    beqz t1, uart_wait_rx
    
    # Read character
    lw a0, UART_RX_DATA(t0)
    andi a0, a0, 0xFF
    
    ret

/**
 * Send character via UART
 * Input: a0 = character to send
 */
uart_putchar:
    li t0, UART_BASE
    
uart_wait_tx:
    lw t1, UART_STATUS(t0)
    andi t1, t1, UART_TX_READY
    beqz t1, uart_wait_tx
    
    # Send character
    sw a0, UART_TX_DATA(t0)
    
    ret

/**
 * Print string via UART
 * Input: a0 = string address
 */
uart_print_string:
    addi sp, sp, -8
    sw ra, 0(sp)
    sw t0, 4(sp)
    
    mv t0, a0
    
print_loop:
    lb a0, 0(t0)
    beqz a0, print_done
    
    call uart_putchar
    addi t0, t0, 1
    j print_loop
    
print_done:
    lw t0, 4(sp)
    lw ra, 0(sp)
    addi sp, sp, 8
    ret

/**
 * Print newline
 */
uart_print_newline:
    addi sp, sp, -4
    sw ra, 0(sp)
    
    li a0, CHAR_CR
    call uart_putchar
    li a0, CHAR_LF
    call uart_putchar
    
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

/**
 * Print hexadecimal value
 * Input: a0 = value to print
 */
uart_print_hex:
    addi sp, sp, -12
    sw ra, 0(sp)
    sw t0, 4(sp)
    sw t1, 8(sp)
    
    # Print "0x" prefix
    li a0, '0'
    call uart_putchar
    li a0, 'x'
    call uart_putchar
    
    # Print 8 hex digits
    lw t0, 4(sp)  # Restore original value
    li t1, 8      # Number of digits
    
hex_loop:
    # Extract top nibble
    srli a0, t0, 28
    andi a0, a0, 0xF
    
    # Convert to ASCII
    li t2, 10
    blt a0, t2, hex_digit
    addi a0, a0, 'A' - 10
    j hex_print
hex_digit:
    addi a0, a0, '0'
hex_print:
    call uart_putchar
    
    # Shift for next nibble
    slli t0, t0, 4
    addi t1, t1, -1
    bnez t1, hex_loop
    
    lw t1, 8(sp)
    lw t0, 4(sp)
    lw ra, 0(sp)
    addi sp, sp, 12
    ret

/**
 * Compare two strings
 * Input: a0 = string1, a1 = string2
 * Output: a0 = 0 if equal, non-zero if different
 */
string_compare:
    lb t0, 0(a0)
    lb t1, 0(a1)
    
    bne t0, t1, strings_different
    
    beqz t0, strings_equal  # Both null terminators
    
    addi a0, a0, 1
    addi a1, a1, 1
    j string_compare

strings_equal:
    li a0, 0
    ret

strings_different:
    li a0, 1
    ret

/**
 * Delay function
 * Input: a0 = delay in milliseconds
 */
delay_ms:
    addi sp, sp, -12
    sw t0, 0(sp)
    sw t1, 4(sp)
    sw t2, 8(sp)
    
    li t0, TIMER_BASE
    lw t1, TIMER_COUNT(t0)
    
    # Calculate target (assuming 1ms timer resolution)
    add t2, t1, a0
    
delay_loop:
    lw t1, TIMER_COUNT(t0)
    bltu t1, t2, delay_loop
    
    lw t2, 8(sp)
    lw t1, 4(sp)
    lw t0, 0(sp)
    addi sp, sp, 12
    ret

/**
 * Hang function
 */
hang:
    j hang

# ============================================================================
# Data Section
# ============================================================================

.section .data

# Command buffer
.equ CMD_BUFFER_SIZE, 128
cmd_buffer:      .space CMD_BUFFER_SIZE
cmd_length:      .word 0

.section .rodata

welcome_msg:
    .ascii "MHX Simple System UART Echo Test\n"
    .ascii "Copyright 2025 MHX Neural\n"
    .ascii "================================\n\0"

help_msg:
    .ascii "Commands:\n"
    .ascii "  help   - Show this help\n"
    .ascii "  status - Show system status\n"
    .ascii "  test   - Run UART test\n"
    .ascii "  reset  - Reset system\n\n\0"

prompt_msg:
    .ascii "MHX> \0"

unknown_cmd_msg:
    .ascii "Unknown command. Type 'help' for help.\n\0"

status_msg:
    .ascii "System Status:\n\0"

uart_status_msg:
    .ascii "  UART Status: \0"

gpio_status_msg:
    .ascii "  GPIO Status: \0"

timer_status_msg:
    .ascii "  Timer Count: \0"

test_start_msg:
    .ascii "Running UART test...\n\0"

test_done_msg:
    .ascii "UART test completed.\n\0"

reset_msg:
    .ascii "Resetting system...\n\0"

# Test pattern (alphabet)
test_pattern:
    .ascii "ABCDEFGHIJKLMNOPQRSTUVWXYZ\0"

# Command strings
cmd_help:    .ascii "help\0"
cmd_status:  .ascii "status\0"
cmd_test:    .ascii "test\0"
cmd_reset:   .ascii "reset\0"