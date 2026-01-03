// Copyright lowRISC contributors.
// Copyright 2025 MHX™ Neural.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/**
 * MHX™ Simple System - Hello World in C
 *
 * This is a simple C program demonstrating basic functionality of the
 * MHX™ Simple System, including UART output, GPIO control, and timer usage.
 */

#include <stdbool.h>
#include <stdint.h>

// Memory map definitions
#define ROM_BASE 0x00000000
#define RAM_BASE 0x20000000
#define UART_BASE 0x40000000
#define GPIO_BASE 0x40010000
#define TIMER_BASE 0x40020000

// UART registers
#define UART_TX_DATA (*(volatile uint32_t *)(UART_BASE + 0x00))
#define UART_STATUS (*(volatile uint32_t *)(UART_BASE + 0x04))
#define UART_TX_READY 0x01

// GPIO registers
#define GPIO_OUT (*(volatile uint32_t *)(GPIO_BASE + 0x00))
#define GPIO_OE (*(volatile uint32_t *)(GPIO_BASE + 0x04))
#define GPIO_IN (*(volatile uint32_t *)(GPIO_BASE + 0x08))

// Timer registers
#define TIMER_COUNT (*(volatile uint32_t *)(TIMER_BASE + 0x00))
#define TIMER_COMPARE (*(volatile uint32_t *)(TIMER_BASE + 0x04))
#define TIMER_CTRL (*(volatile uint32_t *)(TIMER_BASE + 0x08))

// Function prototypes
void uart_putchar(char c);
void uart_puts(const char *str);
void uart_puthex(uint32_t val);
void delay_ms(uint32_t ms);
void gpio_init(void);
void timer_init(void);
void demo_ternary_simulation(void);

/**
 * Main program entry point
 */
int main(void) {
  // Initialize peripherals
  uart_puts("Initializing MHX™ Simple System...\n");
  gpio_init();
  timer_init();

  // Print welcome message
  uart_puts("========================================\n");
  uart_puts("MHX™ Simple System - Hello World in C\n");
  uart_puts("Copyright 2025 MHX™ Neural\n");
  uart_puts("========================================\n");

  // Show system information
  uart_puts("System Information:\n");
  uart_puts("  CPU: MHX™ Core (RISC-V + Ternary Extensions)\n");
  uart_puts("  ROM: 64KB at 0x00000000\n");
  uart_puts("  RAM: 64KB at 0x20000000\n");
  uart_puts("  Clock: 100 MHz\n\n");

  // Demonstrate GPIO functionality
  uart_puts("GPIO Demo: LED Pattern Test\n");
  for (int pattern = 0; pattern < 8; pattern++) {
    uart_puts("Pattern ");
    uart_puthex(pattern);
    uart_puts(": ");

    for (int i = 0; i < 8; i++) {
      uint8_t led_value = (pattern << i) | (pattern >> (8 - i));
      GPIO_OUT = led_value;
      uart_puthex(led_value);
      uart_puts(" ");
      delay_ms(200);
    }
    uart_puts("\n");
  }

  // Demonstrate timer functionality
  uart_puts("\nTimer Demo: Measuring Delays\n");
  for (int delay_val = 100; delay_val <= 1000; delay_val += 100) {
    uint32_t start_time = TIMER_COUNT;
    delay_ms(delay_val);
    uint32_t end_time = TIMER_COUNT;
    uint32_t elapsed = end_time - start_time;

    uart_puts("Delay ");
    uart_puthex(delay_val);
    uart_puts(" ms, Measured: ");
    uart_puthex(elapsed);
    uart_puts(" timer ticks\n");
  }

  // Demonstrate ternary processing simulation
  uart_puts("\nTernary Processing Demo:\n");
  demo_ternary_simulation();

  // Main loop with heartbeat
  uart_puts("\nEntering main loop (heartbeat on LED 0)...\n");
  uint32_t counter = 0;
  while (1) {
    // Heartbeat LED
    GPIO_OUT = (GPIO_OUT & 0xFE) | (counter & 1);

    // Print status every 10 seconds
    if ((counter % 1000) == 0) {
      uart_puts("Heartbeat: ");
      uart_puthex(counter / 100);
      uart_puts(" seconds, Timer: ");
      uart_puthex(TIMER_COUNT);
      uart_puts("\n");
    }

    delay_ms(10);
    counter++;
  }

  return 0;  // Never reached
}

/**
 * Initialize GPIO peripheral
 */
void gpio_init(void) {
  // Set all pins as outputs
  GPIO_OE = 0xFF;

  // Clear all outputs
  GPIO_OUT = 0x00;
}

/**
 * Initialize timer peripheral
 */
void timer_init(void) {
  // Set timer compare for 1ms ticks (100MHz / 1000)
  TIMER_COMPARE = 100000;

  // Reset counter
  TIMER_COUNT = 0;

  // Enable timer
  TIMER_CTRL = 1;
}

/**
 * Send a character via UART
 */
void uart_putchar(char c) {
  // Wait for transmitter ready
  while (!(UART_STATUS & UART_TX_READY)) {
    // Wait
  }

  // Send character
  UART_TX_DATA = c;
}

/**
 * Send a string via UART
 */
void uart_puts(const char *str) {
  while (*str) {
    uart_putchar(*str++);
  }
}

/**
 * Send a hexadecimal value via UART
 */
void uart_puthex(uint32_t val) {
  uart_puts("0x");

  for (int i = 28; i >= 0; i -= 4) {
    uint8_t nibble = (val >> i) & 0xF;
    if (nibble < 10) {
      uart_putchar('0' + nibble);
    } else {
      uart_putchar('A' + nibble - 10);
    }
  }
}

/**
 * Delay function using timer
 */
void delay_ms(uint32_t ms) {
  uint32_t start = TIMER_COUNT;
  uint32_t target = start + (ms * 100);  // 100 ticks per ms

  while (TIMER_COUNT < target) {
    // Wait
  }
}

/**
 * Simulate ternary processing operations
 */
void demo_ternary_simulation(void) {
  uart_puts("Simulating MHX™ Ternary Operations:\n");

  // Ternary patterns (simulated with regular integers)
  uint32_t ternary_a = 0xAAAA5555;  // Pattern of +1, 0, -1, +1, ...
  uint32_t ternary_b = 0x5555AAAA;  // Pattern of 0, +1, +1, 0, ...

  uart_puts("Ternary A: ");
  uart_puthex(ternary_a);
  uart_puts("\n");

  uart_puts("Ternary B: ");
  uart_puthex(ternary_b);
  uart_puts("\n");

  // Simulate ternary addition
  // In real MHX™ hardware, this would use TADD instruction
  uint32_t ternary_sum = ternary_a + ternary_b;  // Simplified simulation
  uart_puts("TADD simulation: ");
  uart_puthex(ternary_sum);
  uart_puts("\n");

  // Simulate ternary multiplication
  // In real MHX™ hardware, this would use TMUL instruction
  uint32_t ternary_product = ternary_a ^ ternary_b;  // Simplified simulation
  uart_puts("TMUL simulation: ");
  uart_puthex(ternary_product);
  uart_puts("\n");

  // Simulate neural processing
  // In real MHX™ hardware, this would use NEURON instruction
  uint32_t weights = ternary_a;
  uint32_t inputs = ternary_b;
  uint32_t neuron_result = (weights & inputs) | ((~weights) & (~inputs));
  uart_puts("NEURON simulation: ");
  uart_puthex(neuron_result);
  uart_puts("\n");

  // Simulate activation function
  // In real MHX™ hardware, this would use ACTIVATE instruction
  uint32_t activated = (neuron_result > 0x80000000) ? 0xAAAAAAAA : 0x55555555;
  uart_puts("ACTIVATE simulation: ");
  uart_puthex(activated);
  uart_puts("\n");

  uart_puts("Note: These are software simulations.\n");
  uart_puts("Real MHX™ hardware would execute these as single instructions!\n");
}

/**
 * Basic startup code (usually in assembly, but simplified here)
 */
void _start(void) __attribute__((naked, section(".text.boot")));
void _start(void) {
  // Set stack pointer (normally done in assembly)
  asm volatile("li sp, 0x20010000");  // Top of RAM

  // Jump to main
  main();

  // Hang if main returns
  while (1) {
    // Infinite loop
  }
}