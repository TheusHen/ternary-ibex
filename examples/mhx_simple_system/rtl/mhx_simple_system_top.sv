// Copyright lowRISC contributors.
// Copyright 2025 MHX Neural.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/**
 * MHX Simple System FPGA Top Level
 *
 * This module provides the top-level interface for FPGA implementation,
 * including clock generation, reset handling, and I/O mapping for
 * different development boards.
 */

module mhx_simple_system_top (
    // Clock and reset
    input  logic clk_100mhz,
    input  logic rst_n,

    // UART interface
    output logic uart_tx,
    input  logic uart_rx,

    // GPIO interface (LEDs and buttons)
    output logic [7:0] led,
    input  logic [3:0] btn,
    input  logic [3:0] sw,

    // Optional SPI interface
    output logic spi_sck,
    output logic spi_mosi,
    input  logic spi_miso,
    output logic spi_cs
);

    // Clock and reset signals
    logic clk_sys;
    logic rst_sys_n;

    // GPIO interface
    logic [7:0] gpio_out;
    logic [7:0] gpio_in;
    logic [7:0] gpio_oe;

    // ========================================================================
    // Clock Generation
    // ========================================================================

    // For now, use the input clock directly
    // In a full implementation, you might want to use MMCM/PLL for:
    // - Clock domain crossing
    // - Different clock frequencies
    // - Clock quality improvement
    assign clk_sys = clk_100mhz;

    // Future enhancement: MMCM/PLL instantiation
    // clocking_wizard u_clk_gen (
    //     .clk_in1  (clk_100mhz),
    //     .clk_out1 (clk_sys),     // 100 MHz system clock
    //     .reset    (~rst_n),
    //     .locked   (clk_locked)
    // );

    // ========================================================================
    // Reset Synchronization
    // ========================================================================

    // Synchronize reset release to avoid metastability
    logic [3:0] rst_sync;

    always_ff @(posedge clk_sys or negedge rst_n) begin
        if (!rst_n) begin
            rst_sync <= 4'b0000;
        end else begin
            rst_sync <= {rst_sync[2:0], 1'b1};
        end
    end

    assign rst_sys_n = rst_sync[3];

    // ========================================================================
    // GPIO Mapping
    // ========================================================================

    // Map board inputs to GPIO
    // Combine buttons and switches into 8-bit input
    assign gpio_in = {sw, btn};

    // Map GPIO outputs to board LEDs
    assign led = gpio_out;

    // Note: gpio_oe (output enable) is handled internally by the system
    // and doesn't need external connections for LED outputs

    // ========================================================================
    // MHX Simple System Instantiation
    // ========================================================================

    mhx_simple_system #(
        .ROMInitFile  (""),  // Can be overridden during synthesis
        .RAMInitFile  ("")   // Can be overridden during synthesis
    ) u_mhx_simple_system (
        .IO_CLK     (clk_sys),
        .IO_RST_N   (rst_sys_n),

        // UART connections
        .uart_tx    (uart_tx),
        .uart_rx    (uart_rx),

        // GPIO connections
        .gpio_out   (gpio_out),
        .gpio_in    (gpio_in),
        .gpio_oe    (gpio_oe),

        // SPI connections
        .spi_sck    (spi_sck),
        .spi_mosi   (spi_mosi),
        .spi_miso   (spi_miso),
        .spi_cs     (spi_cs)
    );

    // ========================================================================
    // Debug and Monitoring (Optional)
    // ========================================================================

    // For debug builds, you can add additional monitoring signals
    `ifdef DEBUG
        // Example: expose internal signals for debug
        (* mark_debug = "true" *) logic debug_clk_sys;
        (* mark_debug = "true" *) logic debug_rst_sys_n;
        (* mark_debug = "true" *) logic [7:0] debug_gpio_out;

        assign debug_clk_sys = clk_sys;
        assign debug_rst_sys_n = rst_sys_n;
        assign debug_gpio_out = gpio_out;
    `endif

    // ========================================================================
    // Board-Specific Adaptations
    // ========================================================================

    // Different boards may require different I/O configurations
    // This can be controlled by synthesis-time parameters

    `ifdef BOARD_ARTY_A7
        // Arty A7 specific configurations
        // - RGB LEDs available
        // - Pmod connectors for expansion
        // - Built-in UART bridge
    `elsif BOARD_BASYS3// Basys3 specific configurations
        // - 16 LEDs available (using only 8)
        // - 7-segment display available (not used)
        // - VGA connector available (not used)
    `elsif BOARD_NEXYS_A7// Nexys A7 specific configurations
        // - More resources available
        // - Ethernet, audio, etc. (not used in this design)
    `endif

    // ========================================================================
    // Power Management (Optional)
    // ========================================================================

    // For battery-powered applications, you might want to add:
    // - Clock gating based on activity
    // - Power domain control
    // - Sleep/wake functionality
    // Example clock gating (disabled by default)
    `ifdef ENABLE_CLOCK_GATING
        logic clock_enable;
        logic gated_clk;

        // Simple activity-based clock gating
        assign clock_enable = |gpio_out || uart_tx;

        // Clock gating cell (would need primitive instantiation)
        // BUFGCE u_clock_gate (
        //     .I  (clk_sys),
        //     .CE (clock_enable),
        //     .O  (gated_clk)
        // );
    `endif

    // ========================================================================
    // Performance Monitoring (Optional)
    // ========================================================================

    `ifdef ENABLE_PERFORMANCE_COUNTERS
        // Example: count clock cycles, instruction execution, etc.
        logic [31:0] cycle_counter;
        logic [31:0] instruction_counter;

        always_ff @(posedge clk_sys or negedge rst_sys_n) begin
            if (!rst_sys_n) begin
                cycle_counter <= 32'h0;
            end else begin
                cycle_counter <= cycle_counter + 1;
            end
        end

                end

        // Instruction counting would require access to core signals
        // This is just a placeholder
        assign instruction_counter = 32'h0;
    `endif

endmodule
