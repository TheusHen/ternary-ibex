# Copyright lowRISC contributors.
# Copyright 2025 MHX Neural.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Generate ternary math validation test

# Name of the program $(PROGRAM).c will be added as a source file
PROGRAM = ternary_math_validation
PROGRAM_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
# Any extra source files to include in the build. Use the upper case .S
# extension for assembly files
EXTRA_SRCS :=

include ${PROGRAM_DIR}/../simple_system/common/common.mk