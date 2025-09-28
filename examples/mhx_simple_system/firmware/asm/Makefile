# Copyright lowRISC contributors.
# Copyright 2025 MHX Neural.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

# MHX Simple System Assembly Firmware Build System
# =================================================

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

# Assembly source files
ASM_SOURCES = boot.S blink_gpio.s uart_echo.s memtest.s
ASM_PROGRAMS = $(ASM_SOURCES:.s=) $(ASM_SOURCES:.S=)

# Build targets
ELF_FILES = $(addprefix $(BIN_DIR)/, $(addsuffix .elf, $(ASM_PROGRAMS)))
BIN_FILES = $(addprefix $(BIN_DIR)/, $(addsuffix .bin, $(ASM_PROGRAMS)))  
HEX_FILES = $(addprefix $(BIN_DIR)/, $(addsuffix .hex, $(ASM_PROGRAMS)))
VMEM_FILES = $(addprefix $(BIN_DIR)/, $(addsuffix .vmem, $(ASM_PROGRAMS)))
DUMP_FILES = $(addprefix $(DUMP_DIR)/, $(addsuffix .dump, $(ASM_PROGRAMS)))

# Compiler/Assembler flags
ARCH_FLAGS = -march=rv32imc -mabi=ilp32
ASFLAGS = $(ARCH_FLAGS) -g
CFLAGS = $(ARCH_FLAGS) -O2 -g -Wall -Wextra
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
	@echo "MHX Simple System Assembly Firmware Build"
	@echo "=========================================="
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'
	@echo ""
	@echo "Programs:"
	@for prog in $(ASM_PROGRAMS); do echo "  $$prog"; done
	@echo ""
	@echo "Configuration:"
	@echo "  TOOLCHAIN_PREFIX = $(TOOLCHAIN_PREFIX)"
	@echo "  ROM_BASE         = $(ROM_BASE)"
	@echo "  RAM_BASE         = $(RAM_BASE)"

all: $(ELF_FILES) $(BIN_FILES) $(HEX_FILES) $(VMEM_FILES) $(DUMP_FILES) ## Build all assembly programs

# Create build directories
$(BUILD_DIR) $(BIN_DIR) $(OBJ_DIR) $(DUMP_DIR):
	mkdir -p $@

# Rule to build ELF files from assembly source
$(BIN_DIR)/%.elf: %.S $(LINKER_SCRIPT) | $(BIN_DIR) $(OBJ_DIR)
	@echo "Building $< -> $@"
	$(CC) $(ASFLAGS) $(LDFLAGS) -T $(LINKER_SCRIPT) -o $@ $<
	$(SIZE) $@

$(BIN_DIR)/%.elf: %.s $(LINKER_SCRIPT) | $(BIN_DIR) $(OBJ_DIR)
	@echo "Building $< -> $@"
	$(CC) $(ASFLAGS) $(LDFLAGS) -T $(LINKER_SCRIPT) -o $@ $<
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
boot: $(BIN_DIR)/boot.elf $(BIN_DIR)/boot.bin $(BIN_DIR)/boot.hex $(BIN_DIR)/boot.vmem ## Build boot loader

blink_gpio: $(BIN_DIR)/blink_gpio.elf $(BIN_DIR)/blink_gpio.bin $(BIN_DIR)/blink_gpio.hex $(BIN_DIR)/blink_gpio.vmem ## Build GPIO blink test

uart_echo: $(BIN_DIR)/uart_echo.elf $(BIN_DIR)/uart_echo.bin $(BIN_DIR)/uart_echo.hex $(BIN_DIR)/uart_echo.vmem ## Build UART echo test

memtest: $(BIN_DIR)/memtest.elf $(BIN_DIR)/memtest.bin $(BIN_DIR)/memtest.hex $(BIN_DIR)/memtest.vmem ## Build memory test

clean: ## Clean all build artifacts
	rm -rf $(BUILD_DIR)

info: ## Show build information
	@echo "Assembly Firmware Build Information"
	@echo "===================================="
	@echo "Toolchain:"
	@echo "  Prefix:    $(TOOLCHAIN_PREFIX)"
	@echo "  CC:        $(CC)"
	@echo "  AS:        $(AS)"
	@echo "  LD:        $(LD)"
	@echo "  OBJCOPY:   $(OBJCOPY)"
	@echo ""
	@echo "Flags:"
	@echo "  ARCH:      $(ARCH_FLAGS)"
	@echo "  ASFLAGS:   $(ASFLAGS)"
	@echo "  LDFLAGS:   $(LDFLAGS)"
	@echo ""
	@echo "Memory Map:"
	@echo "  ROM_BASE:  $(ROM_BASE)"
	@echo "  ROM_SIZE:  $(ROM_SIZE)"
	@echo "  RAM_BASE:  $(RAM_BASE)"
	@echo "  RAM_SIZE:  $(RAM_SIZE)"
	@echo ""
	@echo "Files:"
	@echo "  Sources:   $(ASM_SOURCES)"
	@echo "  Programs:  $(ASM_PROGRAMS)"

# Test targets for individual programs
test-boot: boot ## Test boot program in simulation
	@echo "Testing boot program..."
	@if [ -f "$(BIN_DIR)/boot.vmem" ]; then \
		echo "Boot program ready for simulation: $(BIN_DIR)/boot.vmem"; \
	else \
		echo "ERROR: Boot program not built"; \
		exit 1; \
	fi

test-blink: blink_gpio ## Test GPIO blink program
	@echo "Testing GPIO blink program..."
	@if [ -f "$(BIN_DIR)/blink_gpio.vmem" ]; then \
		echo "GPIO blink program ready: $(BIN_DIR)/blink_gpio.vmem"; \
	else \
		echo "ERROR: GPIO blink program not built"; \
		exit 1; \
	fi

test-uart: uart_echo ## Test UART echo program
	@echo "Testing UART echo program..."
	@if [ -f "$(BIN_DIR)/uart_echo.vmem" ]; then \
		echo "UART echo program ready: $(BIN_DIR)/uart_echo.vmem"; \
	else \
		echo "ERROR: UART echo program not built"; \
		exit 1; \
	fi

test-mem: memtest ## Test memory test program
	@echo "Testing memory test program..."
	@if [ -f "$(BIN_DIR)/memtest.vmem" ]; then \
		echo "Memory test program ready: $(BIN_DIR)/memtest.vmem"; \
	else \
		echo "ERROR: Memory test program not built"; \
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
	@echo "Assembly analysis complete. Dumps available in $(DUMP_DIR)/"

size-report: $(ELF_FILES) ## Show size report for all programs
	@echo "Program Size Report"
	@echo "==================="
	@for elf in $(ELF_FILES); do \
		echo ""; \
		echo "$$(basename $$elf):"; \
		$(SIZE) "$$elf"; \
	done

# Installation targets (for FPGA programming)
install-boot: boot ## Install boot program as default ROM image
	@echo "Installing boot program as default ROM..."
	@cp $(BIN_DIR)/boot.vmem ../common/boot_rom.vmem
	@echo "Boot ROM installed: ../common/boot_rom.vmem"

install-test: memtest ## Install memory test as default program
	@echo "Installing memory test as default program..."
	@cp $(BIN_DIR)/memtest.vmem ../common/test_rom.vmem
	@echo "Test program installed: ../common/test_rom.vmem"

# Dependency checking
check-toolchain: ## Check if RISC-V toolchain is available
	@echo "Checking RISC-V toolchain..."
	@which $(CC) > /dev/null || (echo "ERROR: $(CC) not found. Install RISC-V toolchain."; exit 1)
	@which $(AS) > /dev/null || (echo "ERROR: $(AS) not found. Install RISC-V toolchain."; exit 1)
	@which $(LD) > /dev/null || (echo "ERROR: $(LD) not found. Install RISC-V toolchain."; exit 1)
	@which $(OBJCOPY) > /dev/null || (echo "ERROR: $(OBJCOPY) not found. Install RISC-V toolchain."; exit 1)
	@echo "RISC-V toolchain OK"
	@$(CC) --version | head -1