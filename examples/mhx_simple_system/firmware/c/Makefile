# Copyright lowRISC contributors.
# Copyright 2025 MHX Neural.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

# MHX Simple System C Firmware Build System
# ==========================================

# Toolchain configuration
TOOLCHAIN_PREFIX ?= riscv32-unknown-elf
CC = $(TOOLCHAIN_PREFIX)-gcc
AS = $(TOOLCHAIN_PREFIX)-as
LD = $(TOOLCHAIN_PREFIX)-ld
OBJCOPY = $(TOOLCHAIN_PREFIX)-objcopy
OBJDUMP = $(TOOLCHAIN_PREFIX)-objdump
SIZE = $(TOOLCHAIN_PREFIX)-size

# Build directories
BUILD_DIR = build
BIN_DIR = $(BUILD_DIR)/bin
OBJ_DIR = $(BUILD_DIR)/obj
DUMP_DIR = $(BUILD_DIR)/dump

# C source files
C_SOURCES = hello_mhx.c
C_PROGRAMS = $(C_SOURCES:.c=)

# Build targets
ELF_FILES = $(addprefix $(BIN_DIR)/, $(addsuffix .elf, $(C_PROGRAMS)))
BIN_FILES = $(addprefix $(BIN_DIR)/, $(addsuffix .bin, $(C_PROGRAMS)))
HEX_FILES = $(addprefix $(BIN_DIR)/, $(addsuffix .hex, $(C_PROGRAMS)))
VMEM_FILES = $(addprefix $(BIN_DIR)/, $(addsuffix .vmem, $(C_PROGRAMS)))
DUMP_FILES = $(addprefix $(DUMP_DIR)/, $(addsuffix .dump, $(C_PROGRAMS)))

# Compiler/linker flags
ARCH_FLAGS = -march=rv32imc -mabi=ilp32
CFLAGS = $(ARCH_FLAGS) -O2 -g -Wall -Wextra -std=c99 -ffreestanding -nostdlib
LDFLAGS = $(ARCH_FLAGS) -nostdlib -nostartfiles

# Linker script
LINKER_SCRIPT = ../common/mhx_simple_system.ld

# Memory map (must match hardware)
ROM_BASE = 0x00000000
ROM_SIZE = 0x00010000
RAM_BASE = 0x20000000
RAM_SIZE = 0x00010000

.PHONY: all clean help info
.DEFAULT_GOAL := all

help: ## Show this help message
	@echo "MHX Simple System C Firmware Build"
	@echo "==================================="
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'
	@echo ""
	@echo "Programs:"
	@for prog in $(C_PROGRAMS); do echo "  $$prog"; done
	@echo ""
	@echo "Configuration:"
	@echo "  TOOLCHAIN_PREFIX = $(TOOLCHAIN_PREFIX)"
	@echo "  ROM_BASE         = $(ROM_BASE)"
	@echo "  RAM_BASE         = $(RAM_BASE)"

all: $(ELF_FILES) $(BIN_FILES) $(HEX_FILES) $(VMEM_FILES) $(DUMP_FILES) ## Build all C programs

# Create build directories
$(BUILD_DIR) $(BIN_DIR) $(OBJ_DIR) $(DUMP_DIR):
	mkdir -p $@

# Rule to build ELF files from C source
$(BIN_DIR)/%.elf: %.c $(LINKER_SCRIPT) | $(BIN_DIR) $(OBJ_DIR)
	@echo "Building $< -> $@"
	$(CC) $(CFLAGS) $(LDFLAGS) -T $(LINKER_SCRIPT) -o $@ $<
	$(SIZE) $@

# Rule to create binary files
$(BIN_DIR)/%.bin: $(BIN_DIR)/%.elf
	@echo "Creating binary $@"
	$(OBJCOPY) -O binary $< $@

# Rule to create hex files
$(BIN_DIR)/%.hex: $(BIN_DIR)/%.elf
	@echo "Creating hex $@"
	$(OBJCOPY) -O ihex $< $@

# Rule to create vmem files (for simulation)
$(BIN_DIR)/%.vmem: $(BIN_DIR)/%.elf
	@echo "Creating vmem $@"
	$(OBJCOPY) -O verilog $< $@

# Rule to create disassembly dumps
$(DUMP_DIR)/%.dump: $(BIN_DIR)/%.elf | $(DUMP_DIR)
	@echo "Creating disassembly $@"
	$(OBJDUMP) -D -S $< > $@

# Individual program targets
hello_mhx: $(BIN_DIR)/hello_mhx.elf $(BIN_DIR)/hello_mhx.bin $(BIN_DIR)/hello_mhx.hex $(BIN_DIR)/hello_mhx.vmem ## Build hello world program

clean: ## Clean all build artifacts
	rm -rf $(BUILD_DIR)

info: ## Show build information
	@echo "C Firmware Build Information"
	@echo "============================="
	@echo "Toolchain:"
	@echo "  Prefix:    $(TOOLCHAIN_PREFIX)"
	@echo "  CC:        $(CC)"
	@echo "  LD:        $(LD)"
	@echo "  OBJCOPY:   $(OBJCOPY)"
	@echo ""
	@echo "Flags:"
	@echo "  ARCH:      $(ARCH_FLAGS)"
	@echo "  CFLAGS:    $(CFLAGS)"
	@echo "  LDFLAGS:   $(LDFLAGS)"
	@echo ""
	@echo "Memory Map:"
	@echo "  ROM_BASE:  $(ROM_BASE)"
	@echo "  ROM_SIZE:  $(ROM_SIZE)"
	@echo "  RAM_BASE:  $(RAM_BASE)"
	@echo "  RAM_SIZE:  $(RAM_SIZE)"
	@echo ""
	@echo "Files:"
	@echo "  Sources:   $(C_SOURCES)"
	@echo "  Programs:  $(C_PROGRAMS)"

# Test targets
test-hello: hello_mhx ## Test hello world program
	@echo "Testing hello world program..."
	@if [ -f "$(BIN_DIR)/hello_mhx.vmem" ]; then \
		echo "Hello world program ready: $(BIN_DIR)/hello_mhx.vmem"; \
	else \
		echo "ERROR: Hello world program not built"; \
		exit 1; \
	fi

# Verification targets
verify: $(ELF_FILES) ## Verify all programs are correctly built
	@echo "Verifying built programs..."
	@for elf in $(ELF_FILES); do \
		echo "Checking $$elf..."; \
		if [ -f "$$elf" ]; then \
			$(SIZE) "$$elf"; \
			echo "  OK"; \
		else \
			echo "  ERROR: $$elf not found"; \
			exit 1; \
		fi; \
	done
	@echo "All programs verified successfully!"

# Analysis targets
analyze: $(DUMP_FILES) ## Generate disassembly for all programs
	@echo "C program analysis complete. Dumps available in $(DUMP_DIR)/"

size-report: $(ELF_FILES) ## Show size report for all programs
	@echo "Program Size Report"
	@echo "==================="
	@for elf in $(ELF_FILES); do \
		echo ""; \
		echo "$$(basename $$elf):"; \
		$(SIZE) "$$elf"; \
	done

# Installation targets
install-hello: hello_mhx ## Install hello program as default
	@echo "Installing hello program as default..."
	@cp $(BIN_DIR)/hello_mhx.vmem ../common/hello_rom.vmem
	@echo "Hello program installed: ../common/hello_rom.vmem"

# Dependency checking
check-toolchain: ## Check if RISC-V toolchain is available
	@echo "Checking RISC-V toolchain..."
	@which $(CC) > /dev/null || (echo "ERROR: $(CC) not found. Install RISC-V toolchain."; exit 1)
	@which $(LD) > /dev/null || (echo "ERROR: $(LD) not found. Install RISC-V toolchain."; exit 1)
	@which $(OBJCOPY) > /dev/null || (echo "ERROR: $(OBJCOPY) not found. Install RISC-V toolchain."; exit 1)
	@echo "RISC-V toolchain OK"
	@$(CC) --version | head -1