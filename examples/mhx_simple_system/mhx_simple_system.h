// Copyright lowRISC contributors.
// Copyright 2025 MHX Neural.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "verilated_toplevel.h"
#include "verilator_memutil.h"

class MhxSystem {
 public:
  static constexpr uint32_t kRAM_BaseAddr = 0x100000u;
  static constexpr uint32_t kRAM_SizeBytes = 0x100000u;

  MhxSystem(const char *ram_hier_path, int ram_size_words);
  virtual ~MhxSystem() {}
  virtual int Main(int argc, char **argv);

  // Return an ISA string, as understood by Spike, for the system being
  // simulated. Includes MHX ternary extensions.
  std::string GetIsaString() const;

 protected:
  mhx_simple_system _top;
  VerilatorMemUtil _memutil;
  MemArea _ram;

  virtual int Setup(int argc, char **argv, bool &exit_app);
  virtual void Run();
  virtual bool Finish();
};