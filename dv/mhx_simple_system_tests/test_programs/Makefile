# Copyright lowRISC contributors.
# Copyright 2025 MHX Neural.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

# Makefile for MHX test program

PROGRAM = mhx_test_program
PROGRAM_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

# Use the common build framework from simple_system if available
# Otherwise provide minimal build setup
ifeq ($(wildcard ../../../examples/sw/simple_system/common/common.mk),)
# Minimal build setup for testing
CC = riscv32-unknown-elf-gcc
OBJCOPY = riscv32-unknown-elf-objcopy
OBJDUMP = riscv32-unknown-elf-objdump

CFLAGS = -march=rv32imc -mabi=ilp32 -static -mcmodel=medany
CFLAGS += -fvisibility=hidden -nostdlib -nostartfiles
CFLAGS += -Os -g
LDFLAGS = -T$(PROGRAM_DIR)/link.ld

all: $(PROGRAM).vmem

$(PROGRAM).elf: $(PROGRAM).c crt0.S link.ld
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ crt0.S $(PROGRAM).c

$(PROGRAM).bin: $(PROGRAM).elf
	$(OBJCOPY) -O binary $< $@

$(PROGRAM).vmem: $(PROGRAM).elf
	$(OBJCOPY) -O verilog $< $@

$(PROGRAM).dis: $(PROGRAM).elf
	$(OBJDUMP) -D $< > $@

clean:
	rm -f $(PROGRAM).elf $(PROGRAM).bin $(PROGRAM).vmem $(PROGRAM).dis

.PHONY: all clean

else
# Use existing build framework
include ../../../examples/sw/simple_system/common/common.mk
endif