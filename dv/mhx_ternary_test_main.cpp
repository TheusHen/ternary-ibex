// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/**
 * Main function for MHX Ternary Extension Verilator testbench
 */

#include <iostream>
#include <memory>

#include "verilated.h"
#include "verilated_vcd_c.h"
#include "Vmhx_ternary_test.h"

// Current simulation time (64-bit unsigned)
vluint64_t main_time = 0;

// Called by $time in Verilog
double sc_time_stamp() {
    return main_time;  // Note does conversion to real, to match SystemC
}

int main(int argc, char** argv) {
    // This is a more complicated example, please also see the simpler examples/make_hello_c.

    // Prevent unused variable warnings
    if (false && argc && argv) {}

    // Construct a VerilatedContext to hold simulation time, etc.
    std::unique_ptr<VerilatedContext> contextp{new VerilatedContext};

    // Pass arguments so Verilated code can see them, e.g. $value$plusargs
    // This needs to be called before you create any model
    contextp->commandArgs(argc, argv);

    // Set debug level, 0 is off, 9 is highest presently used
    // May be overridden by commandArgs argument parsing
    contextp->debug(0);

    // Randomization reset policy
    // May be overridden by commandArgs argument parsing
    contextp->randReset(2);

    // Construct the Verilated model, from Vmhx_ternary_test.h generated from Verilating "mhx_ternary_test.sv"
    std::unique_ptr<Vmhx_ternary_test> top{new Vmhx_ternary_test{contextp.get(), "TOP"}};

    // Set up trace dumping
    Verilated::traceEverOn(true);
    std::unique_ptr<VerilatedVcdC> tfp{new VerilatedVcdC};
    top->trace(tfp.get(), 99);  // Trace 99 levels of hierarchy
    tfp->open("mhx_ternary_test.vcd");

    // Simulate until the testbench finishes
    while (!contextp->gotFinish()) {
        // Evaluate model
        top->eval();

        // Dump trace data for this cycle
        if (tfp) tfp->dump(main_time);

        // Advance time
        main_time++;
    }

    // Close trace file
    if (tfp) tfp->close();

    // Final model cleanup
    top->final();

    // Print simulation summary
    std::cout << "Simulation completed after " << main_time << " time units." << std::endl;
    
    return 0;
}