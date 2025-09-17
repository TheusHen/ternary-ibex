// Copyright lowRISC contributors.
// Copyright 2025 MHX Neural.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/**
 * Main C++ driver for MHX Ternary Coverage Analysis
 *
 * This program runs the comprehensive coverage testbench and generates
 * detailed coverage reports for all ternary operations and neural units.
 */

#include <iostream>
#include <fstream>
#include <memory>
#include <cstdlib>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include <verilated_cov.h>

#include "Vmhx_ternary_coverage_test.h"

// Global simulation time
vluint64_t main_time = 0;

// Called by $time in Verilog
double sc_time_stamp() {
    return main_time;
}

int main(int argc, char** argv) {
    // Initialize Verilator
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);

    // Create instance of our module under test
    auto dut = std::make_unique<Vmhx_ternary_coverage_test>();

    // Create trace dump
    auto tfp = std::make_unique<VerilatedVcdC>();
    dut->trace(tfp.get(), 99);
    tfp->open("mhx_ternary_coverage.vcd");

    std::cout << "========================================\n";
    std::cout << "MHX Ternary Coverage Analysis\n";
    std::cout << "========================================\n";
    std::cout << "Running comprehensive coverage tests...\n\n";

    // Run simulation
    while (!Verilated::gotFinish() && main_time < 1000000) {
        main_time++;

        // Toggle clock
        if (main_time % 5 == 0) {
            dut->clk = !dut->clk;
        }

        // Evaluate model
        dut->eval();

        // Dump trace
        tfp->dump(main_time);
    }

    // Clean up
    tfp->close();

    std::cout << "\n========================================\n";
    std::cout << "Coverage Analysis Complete\n";
    std::cout << "========================================\n";
    
    // Write coverage data
    if (getenv("COVERAGE")) {
        std::cout << "Writing coverage data...\n";
        Verilated::mkdir("coverage_data");
        VerilatedCov::write("coverage_data/coverage.dat");
        
        std::cout << "Coverage data written to coverage_data/coverage.dat\n";
        std::cout << "Trace file written to mhx_ternary_coverage.vcd\n";
    }

    std::cout << "Analysis completed successfully!\n";

    return 0;
}