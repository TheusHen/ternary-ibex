# Copyright lowRISC contributors.
# Copyright 2025 MHX Neural.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

source ./tcl/yosys_common.tcl

yosys "read_liberty -lib $lr_synth_cell_library_path"
yosys "read_verilog $lr_synth_pre_map_out"

