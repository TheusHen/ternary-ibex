// Copyright lowRISC contributors.
// Copyright 2025 MHX Neural.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include <iostream>
#include <memory>

#include "Vmhx_simple_system_test.h"
#include "verilated.h"
#include "verilated_fst_c.h"

int main(int argc, char **argv) {
  Verilated::commandArgs(argc, argv);

  auto dut = std::make_unique<Vmhx_simple_system_test>();

  // Enable tracing
  Verilated::traceEverOn(true);
  auto trace = std::make_unique<VerilatedFstC>();
  dut->trace(trace.get(), 99);
  trace->open("mhx_simple_system_test.fst");

  std::cout << "Starting MHX Neural T1 Simple System test..." << std::endl;

  vluint64_t time_step = 0;
  const vluint64_t max_time = 1000000;  // 1M time steps

  while (!Verilated::gotFinish() && time_step < max_time) {
    dut->eval();
    trace->dump(time_step);
    time_step++;

    // Print progress every 100k cycles
    if (time_step % 100000 == 0) {
      std::cout << "Simulation time: " << time_step << std::endl;
    }
  }

  trace->close();

  if (time_step >= max_time) {
    std::cout << "Test timed out after " << max_time << " time steps"
              << std::endl;
    return 1;
  }

  std::cout << "MHX Neural T1 Simple System test completed successfully"
            << std::endl;
  return 0;
}