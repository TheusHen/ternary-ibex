// Copyright lowRISC contributors.
// Copyright 2025 MHX Neural.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "mhx_simple_system.h"

int main(int argc, char **argv) {
  MhxSystem mhx_system(
      "TOP.mhx_simple_system.u_ram.u_ram.gen_generic.u_impl_generic",
      MhxSystem::kRAM_SizeBytes / 4);

  return mhx_system.Main(argc, argv);
}