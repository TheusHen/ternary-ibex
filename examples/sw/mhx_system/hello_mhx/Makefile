# Copyright lowRISC contributors.
# Copyright 2025 MHX Neural.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Generate a baremetal application for MHX System

# Name of the program $(PROGRAM).c will be added as a source file
PROGRAM = hello_mhx
PROGRAM_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

# Use the common build framework from simple_system
include ${PROGRAM_DIR}/../../simple_system/common/common.mk