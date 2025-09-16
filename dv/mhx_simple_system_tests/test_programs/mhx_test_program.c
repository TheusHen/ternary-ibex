// Copyright lowRISC contributors.
// Copyright 2025 MHX Neural.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/**
 * Simple test program for MHX Neural T1 Simple System
 * Tests basic functionality without requiring complex toolchain
 */

#include <stdint.h>

// Memory map definitions
#define GPIO_BASE_ADDR   0x40000
#define UART_BASE_ADDR   0x50000
#define SIM_CTRL_BASE    0x20000

// Register access macros
#define REG32(addr) (*((volatile uint32_t*)(addr)))

// GPIO registers
#define GPIO_OUT_REG     REG32(GPIO_BASE_ADDR + 0x00)
#define GPIO_IN_REG      REG32(GPIO_BASE_ADDR + 0x04)
#define GPIO_DIR_REG     REG32(GPIO_BASE_ADDR + 0x08)

// UART registers
#define UART_DATA_REG    REG32(UART_BASE_ADDR + 0x00)
#define UART_STATUS_REG  REG32(UART_BASE_ADDR + 0x04)
#define UART_CTRL_REG    REG32(UART_BASE_ADDR + 0x08)

// Simulator control
#define SIM_CTRL_OUT     REG32(SIM_CTRL_BASE + 0x00)
#define SIM_CTRL_CTRL    REG32(SIM_CTRL_BASE + 0x08)

void delay(int cycles) {
    volatile int i;
    for (i = 0; i < cycles; i++) {
        asm volatile ("nop");
    }
}

void test_gpio() {
    // Set all GPIOs as outputs
    GPIO_DIR_REG = 0xFF;
    
    // Test pattern on GPIO
    for (int i = 0; i < 16; i++) {
        GPIO_OUT_REG = i;
        delay(100);
    }
    
    // Set alternating pattern
    GPIO_OUT_REG = 0xAA;
    delay(100);
    GPIO_OUT_REG = 0x55;
    delay(100);
}

void test_uart() {
    // Enable UART transmitter
    UART_CTRL_REG = 0x01;
    
    // Send test message
    const char* msg = "MHX Test\n";
    for (int i = 0; msg[i] != '\0'; i++) {
        // Wait for TX ready
        while (!(UART_STATUS_REG & 0x01));
        UART_DATA_REG = msg[i];
    }
}

void test_ternary_operations() {
    // Placeholder for ternary operations
    // In real implementation, these would use ternary assembly instructions
    uint32_t a = 0xAAAA5555;
    uint32_t b = 0x55AAAAAA;
    uint32_t result = a ^ b; // Simulate ternary ADD
    
    // Output result via GPIO (lower 8 bits)
    GPIO_OUT_REG = result & 0xFF;
    delay(1000);
}

int main() {
    // Initialize test
    test_gpio();
    test_uart();
    test_ternary_operations();
    
    // Signal test completion
    GPIO_OUT_REG = 0xFF; // All LEDs on indicates completion
    
    // Halt simulation
    SIM_CTRL_OUT = 0x01;
    SIM_CTRL_CTRL = 0x01;
    
    return 0;
}