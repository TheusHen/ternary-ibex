# Copyright lowRISC contributors.
# Copyright 2025 MHX Neural.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

# MHX Simple System Build System
# ==============================

# Default configuration
IBEX_CONFIG ?= mhx
MHX_ROOT ?= $(shell pwd)/../..
FUSESOC_CORES_ROOT ?= $(MHX_ROOT)

# Build directories
BUILD_DIR ?= build
SIM_DIR ?= $(BUILD_DIR)/sim
SYN_DIR ?= $(BUILD_DIR)/syn
FIRMWARE_DIR ?= $(BUILD_DIR)/firmware

# Simulation configuration
SIM_CYCLES ?= 1000000
TRACE ?= 0
INTERACTIVE ?= 0

# Synthesis configuration
BOARD ?= arty_a7_35t
PART ?= xc7a35tcsg324-1

# Firmware configuration
TOOLCHAIN_PREFIX ?= riscv32-unknown-elf
FIRMWARE_TARGET ?= hello_test

# FuseSoC options for MHX
FUSESOC_CONFIG_OPTS = --RV32E=0 --RV32M=ibex_pkg::RV32MFast --RV32B=ibex_pkg::RV32BNone \
                      --RegFile=ibex_pkg::RegFileFF --BranchTargetALU=0 --WritebackStage=0 \
                      --ICache=0 --ICacheECC=0 --BranchPredictor=0 --DbgTriggerEn=0 \
                      --SecureIbex=0 --PMPEnable=0 --PMPGranularity=0 --PMPNumRegions=4 \
                      --MHPMCounterNum=0 --MHPMCounterWidth=40

.PHONY: help all clean build-sim run-sim build-firmware build-synth flash
.DEFAULT_GOAL := help

help: ## Show this help message
	@echo "MHX Simple System Build System"
	@echo "==============================="
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'
	@echo ""
	@echo "Configuration:"
	@echo "  IBEX_CONFIG      = $(IBEX_CONFIG)"
	@echo "  BOARD            = $(BOARD)"
	@echo "  FIRMWARE_TARGET  = $(FIRMWARE_TARGET)"
	@echo "  SIM_CYCLES       = $(SIM_CYCLES)"
	@echo "  TRACE            = $(TRACE)"

all: build-sim build-firmware ## Build simulation and firmware

clean: ## Clean all build artifacts
	rm -rf $(BUILD_DIR)
	fusesoc --cores-root=$(FUSESOC_CORES_ROOT) run --target=sim --clean lowrisc:ibex:mhx_simple_system || true

# ============================================================================
# Simulation Targets
# ============================================================================

build-sim: ## Build the Verilator simulation
	@echo "Building MHX Simple System simulation..."
	@mkdir -p $(SIM_DIR)
	fusesoc --cores-root=$(FUSESOC_CORES_ROOT) run --target=sim --setup --build \
		lowrisc:ibex:mhx_simple_system $(FUSESOC_CONFIG_OPTS)

VSIM_BIN = $(MHX_ROOT)/build/lowrisc_ibex_mhx_simple_system_0/sim-verilator/Vmhx_simple_system

$(VSIM_BIN): build-sim

run-sim: $(VSIM_BIN) ## Run the simulation
	@echo "Running MHX Simple System simulation..."
	@TRACE_FLAGS=""; \
	if [ "$(TRACE)" = "1" ]; then TRACE_FLAGS="--trace"; fi; \
	INTERACTIVE_FLAGS=""; \
	if [ "$(INTERACTIVE)" = "1" ]; then INTERACTIVE_FLAGS="--interactive"; fi; \
	$(VSIM_BIN) $$TRACE_FLAGS $$INTERACTIVE_FLAGS --cycles $(SIM_CYCLES)

run-sim-trace: ## Run simulation with tracing enabled
	$(MAKE) run-sim TRACE=1

run-sim-interactive: ## Run simulation in interactive mode
	$(MAKE) run-sim INTERACTIVE=1

# ============================================================================
# Firmware Targets  
# ============================================================================

build-firmware: ## Build all firmware examples
	@echo "Building firmware examples..."
	@$(MAKE) -C firmware/asm all
	@$(MAKE) -C firmware/c all

build-firmware-asm: ## Build assembly firmware examples
	@$(MAKE) -C firmware/asm all

build-firmware-c: ## Build C firmware examples
	@$(MAKE) -C firmware/c all

clean-firmware: ## Clean firmware build artifacts
	@$(MAKE) -C firmware/asm clean
	@$(MAKE) -C firmware/c clean

# ============================================================================
# Synthesis Targets
# ============================================================================

build-synth-vivado: ## Synthesize using Vivado
	@echo "Running Vivado synthesis for $(BOARD)..."
	@mkdir -p $(SYN_DIR)/vivado
	cd syn/tcl && vivado -mode batch -source build_vivado.tcl -tclargs $(BOARD) $(PART)

build-synth-yosys: ## Synthesize using Yosys + nextpnr  
	@echo "Running Yosys synthesis..."
	@mkdir -p $(SYN_DIR)/yosys
	cd syn/yosys && ./build_yosys.sh $(BOARD)

build-synth: build-synth-vivado ## Default synthesis target

# ============================================================================
# FPGA Programming Targets
# ============================================================================

flash: ## Program FPGA bitstream
	@echo "Programming FPGA..."
	@if [ -f "$(SYN_DIR)/vivado/$(BOARD).bit" ]; then \
		echo "Programming with Vivado bitstream..."; \
		openocd -f syn/constraints/$(BOARD)_openocd.cfg -c "program $(SYN_DIR)/vivado/$(BOARD).bit; exit"; \
	else \
		echo "No bitstream found. Run 'make build-synth' first."; \
		exit 1; \
	fi

flash-yosys: ## Program FPGA with Yosys bitstream
	@echo "Programming FPGA with Yosys bitstream..."
	@if [ -f "$(SYN_DIR)/yosys/$(BOARD).bit" ]; then \
		openocd -f syn/constraints/$(BOARD)_openocd.cfg -c "program $(SYN_DIR)/yosys/$(BOARD).bit; exit"; \
	else \
		echo "No Yosys bitstream found. Run 'make build-synth-yosys' first."; \
		exit 1; \
	fi

# ============================================================================
# Test and Verification Targets
# ============================================================================

test: ## Run all tests
	@echo "Running MHX Simple System tests..."
	@$(MAKE) build-firmware
	@$(MAKE) run-sim FIRMWARE_TARGET=boot_test SIM_CYCLES=10000
	@$(MAKE) run-sim FIRMWARE_TARGET=gpio_test SIM_CYCLES=50000
	@$(MAKE) run-sim FIRMWARE_TARGET=uart_test SIM_CYCLES=100000

test-ternary: ## Run ternary extension tests
	@echo "Running ternary extension tests..."
	@$(MAKE) run-sim FIRMWARE_TARGET=ternary_test SIM_CYCLES=100000 TRACE=1

lint: ## Run linting on the design
	@echo "Running lint checks..."
	fusesoc --cores-root=$(FUSESOC_CORES_ROOT) run --target=lint \
		lowrisc:ibex:mhx_simple_system $(FUSESOC_CONFIG_OPTS)

# ============================================================================
# Documentation Targets
# ============================================================================

docs: ## Generate documentation
	@echo "Generating documentation..."
	@mkdir -p $(BUILD_DIR)/docs
	@echo "Documentation generation not yet implemented"

# ============================================================================
# Utility Targets
# ============================================================================

setup: ## Set up build environment
	@echo "Setting up MHX Simple System build environment..."
	@echo "Checking dependencies..."
	@which fusesoc > /dev/null || (echo "ERROR: fusesoc not found. Install with: pip3 install fusesoc"; exit 1)
	@which verilator > /dev/null || (echo "ERROR: verilator not found. Install with: sudo apt-get install verilator"; exit 1)
	@which $(TOOLCHAIN_PREFIX)-gcc > /dev/null || (echo "WARNING: RISC-V toolchain not found. Set TOOLCHAIN_PREFIX or install riscv-gnu-toolchain")
	@echo "Environment setup complete!"

info: ## Show build information
	@echo "MHX Simple System Build Information"
	@echo "===================================="
	@echo "Configuration:"
	@echo "  IBEX_CONFIG      = $(IBEX_CONFIG)"
	@echo "  MHX_ROOT         = $(MHX_ROOT)"
	@echo "  FUSESOC_CORES_ROOT = $(FUSESOC_CORES_ROOT)"
	@echo "  BUILD_DIR        = $(BUILD_DIR)"
	@echo "  BOARD            = $(BOARD)"
	@echo "  PART             = $(PART)"
	@echo "  FIRMWARE_TARGET  = $(FIRMWARE_TARGET)"
	@echo "  TOOLCHAIN_PREFIX = $(TOOLCHAIN_PREFIX)"
	@echo ""
	@echo "FuseSoC Options:"
	@echo "  $(FUSESOC_CONFIG_OPTS)"

# ============================================================================
# Development Targets
# ============================================================================

dev-shell: ## Start development shell with environment variables set
	@echo "Starting MHX development shell..."
	@echo "Environment variables:"
	@echo "  MHX_ROOT=$(MHX_ROOT)"
	@echo "  PATH=$(PATH):$(MHX_ROOT)/bin"
	@bash --rcfile <(echo "PS1='[MHX] \u@\h:\w\$$ '")

# Include board-specific makefiles if they exist
-include syn/constraints/$(BOARD).mk