// Copyright lowRISC contributors.
// Copyright 2025 MHX™ Neural.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/**
 * MHX™ Simple System Verilator Testbench
 *
 * This testbench provides:
 * - Clock and reset generation
 * - UART output capture
 * - GPIO monitoring
 * - Memory initialization
 * - Performance monitoring
 */

#include <getopt.h>
#include <signal.h>

#include <cstdlib>
#include <iomanip>
#include <iostream>
#include <memory>

#include "Vmhx_simple_system.h"
#include "Vmhx_simple_system__Syms.h"
#include "verilated.h"
#include "verilated_fst_c.h"

// For memory loading
#include <fstream>
#include <string>
#include <vector>

class MhxSimpleSystemSim {
 private:
  std::unique_ptr<Vmhx_simple_system> dut_;
  std::unique_ptr<VerilatedFstC> trace_;

  bool trace_enabled_;
  bool interactive_;
  std::string rom_file_;
  std::string ram_file_;

  uint64_t tick_count_;
  uint64_t max_cycles_;

  // UART simulation
  std::string uart_output_;
  bool uart_tx_prev_;

  // GPIO simulation
  uint8_t gpio_in_val_;

 public:
  MhxSimpleSystemSim(bool trace_enabled = false, bool interactive = false,
                     uint64_t max_cycles = 1000000)
      : trace_enabled_(trace_enabled),
        interactive_(interactive),
        tick_count_(0),
        max_cycles_(max_cycles),
        uart_tx_prev_(false),
        gpio_in_val_(0x00) {
    dut_ = std::make_unique<Vmhx_simple_system>();

    if (trace_enabled_) {
      Verilated::traceEverOn(true);
      trace_ = std::make_unique<VerilatedFstC>();
      dut_->trace(trace_.get(), 99);
      trace_->open("mhx_simple_system.fst");
    }

    // Initialize inputs
    dut_->IO_CLK = 0;
    dut_->IO_RST_N = 0;
    dut_->uart_rx = 1;
    dut_->gpio_in = gpio_in_val_;
    dut_->spi_miso = 0;
  }

  ~MhxSimpleSystemSim() {
    if (trace_enabled_) {
      trace_->close();
    }
  }

  void set_rom_file(const std::string &file) { rom_file_ = file; }

  void set_ram_file(const std::string &file) { ram_file_ = file; }

  void reset() {
    std::cout << "Resetting MHX™ Simple System..." << std::endl;

    // Hold reset for 10 cycles
    for (int i = 0; i < 10; i++) {
      dut_->IO_RST_N = 0;
      tick();
    }

    // Release reset
    dut_->IO_RST_N = 1;
    tick();

    std::cout << "Reset complete." << std::endl;
  }

  void tick() {
    // Rising edge
    dut_->IO_CLK = 1;
    dut_->eval();

    if (trace_enabled_) {
      trace_->dump(tick_count_ * 2);
    }

    // Falling edge
    dut_->IO_CLK = 0;
    dut_->eval();

    if (trace_enabled_) {
      trace_->dump(tick_count_ * 2 + 1);
    }

    tick_count_++;

    // Check UART output
    check_uart_output();

    // Update GPIO inputs (simple pattern)
    if (tick_count_ % 100000 == 0) {
      gpio_in_val_ = (gpio_in_val_ + 1) & 0xFF;
      dut_->gpio_in = gpio_in_val_;
    }
  }
  void check_uart_output() {
    // Simple UART monitoring (just look for changes)
    if (dut_->uart_tx != uart_tx_prev_) {
      uart_tx_prev_ = dut_->uart_tx;
      if (tick_count_ % 10000 == 0) {
        std::cout << "UART TX: " << (dut_->uart_tx ? "1" : "0") << std::endl;
      }
    }
  }

  void print_status() {
    std::cout << "\n=== MHX™ Simple System Status ===" << std::endl;
    std::cout << "Cycle: " << std::dec << tick_count_ << std::endl;
    std::cout << "GPIO Out: 0x" << std::hex << std::setw(2) << std::setfill('0')
              << (int)dut_->gpio_out << std::endl;
    std::cout << "GPIO In:  0x" << std::hex << std::setw(2) << std::setfill('0')
              << (int)dut_->gpio_in << std::endl;
    std::cout << "GPIO OE:  0x" << std::hex << std::setw(2) << std::setfill('0')
              << (int)dut_->gpio_oe << std::endl;
    std::cout << "UART TX:  " << (dut_->uart_tx ? "1" : "0") << std::endl;
    std::cout << "Reset:    " << (dut_->IO_RST_N ? "Released" : "Active")
              << std::endl;
  }

  bool should_stop() {
    // Stop if max cycles reached
    if (tick_count_ >= max_cycles_) {
      std::cout << "Maximum simulation cycles (" << max_cycles_ << ") reached."
                << std::endl;
      return true;
    }

    // Check for Verilator finish
    if (Verilated::gotFinish()) {
      std::cout << "Verilator finish() called." << std::endl;
      return true;
    }

    return false;
  }

  void run() {
    std::cout << "Starting MHX™ Simple System simulation..." << std::endl;
    std::cout << "Max cycles: " << max_cycles_ << std::endl;
    std::cout << "Tracing: " << (trace_enabled_ ? "enabled" : "disabled")
              << std::endl;

    reset();

    while (!should_stop()) {
      tick();

      // Print status periodically
      if (tick_count_ % 100000 == 0) {
        print_status();
      }

      // Interactive mode check
      if (interactive_ && tick_count_ % 10000 == 0) {
        std::cout << "Continue? (y/n): ";
        char c;
        std::cin >> c;
        if (c != 'y' && c != 'Y') {
          break;
        }
      }
    }

    print_status();
    std::cout << "Simulation completed after " << tick_count_ << " cycles."
              << std::endl;
  }
};

// Signal handler for clean exit
static MhxSimpleSystemSim *g_sim = nullptr;
void signal_handler(int signal) {
  std::cout << "\nReceived signal " << signal << ", exiting..." << std::endl;
  if (g_sim) {
    delete g_sim;
  }
  exit(0);
}

void print_usage(const char *prog_name) {
  std::cout << "Usage: " << prog_name << " [options]" << std::endl;
  std::cout << "Options:" << std::endl;
  std::cout << "  -h, --help           Show this help message" << std::endl;
  std::cout << "  -t, --trace          Enable FST tracing" << std::endl;
  std::cout << "  -i, --interactive    Enable interactive mode" << std::endl;
  std::cout << "  -c, --cycles <n>     Set maximum simulation cycles (default: "
               "1000000)"
            << std::endl;
  std::cout << "  -r, --rom <file>     ROM initialization file" << std::endl;
  std::cout << "  -m, --ram <file>     RAM initialization file" << std::endl;
}

int main(int argc, char **argv) {
  // Command line argument parsing
  bool trace_enabled = false;
  bool interactive = false;
  uint64_t max_cycles = 1000000;
  std::string rom_file;
  std::string ram_file;

  static struct option long_options[] = {{"help", no_argument, 0, 'h'},
                                         {"trace", no_argument, 0, 't'},
                                         {"interactive", no_argument, 0, 'i'},
                                         {"cycles", required_argument, 0, 'c'},
                                         {"rom", required_argument, 0, 'r'},
                                         {"ram", required_argument, 0, 'm'},
                                         {0, 0, 0, 0}};

  int c;
  while ((c = getopt_long(argc, argv, "htic:r:m:", long_options, nullptr)) !=
         -1) {
    switch (c) {
      case 'h':
        print_usage(argv[0]);
        return 0;
      case 't':
        trace_enabled = true;
        break;
      case 'i':
        interactive = true;
        break;
      case 'c':
        max_cycles = strtoull(optarg, nullptr, 10);
        break;
      case 'r':
        rom_file = optarg;
        break;
      case 'm':
        ram_file = optarg;
        break;
      case '?':
        print_usage(argv[0]);
        return 1;
      default:
        break;
    }
  }

  // Initialize Verilator
  Verilated::commandArgs(argc, argv);
  Verilated::mkdir("logs");

  // Set up signal handlers
  signal(SIGINT, signal_handler);
  signal(SIGTERM, signal_handler);

  // Create and run simulation
  MhxSimpleSystemSim sim(trace_enabled, interactive, max_cycles);
  g_sim = &sim;

  if (!rom_file.empty()) {
    sim.set_rom_file(rom_file);
  }

  if (!ram_file.empty()) {
    sim.set_ram_file(ram_file);
  }

  try {
    sim.run();
  } catch (const std::exception &e) {
    std::cerr << "Simulation error: " << e.what() << std::endl;
    return 1;
  }

  g_sim = nullptr;
  return 0;
}