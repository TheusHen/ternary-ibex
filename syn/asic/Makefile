# MHX™ Ternary Extension - ASIC Synthesis Configuration
# Target: Skywater 130nm Open PDK
# Tool: Yosys + OpenLane

# Design configuration
DESIGN_NAME := mhx_ternary_top
DESIGN_TOP  := ibex_core

# Ternary extension modules
TERNARY_MODULES := \
    ibex_ternary_alu \
    ibex_ternary_regfile \
    ibex_ternary_advanced \
    ibex_neural_unit \
    ibex_neural_unit_enhanced \
    ibex_ternary_conv_pool \
    ibex_ternary_dma \
    ibex_ternary_lsu \
    ibex_ternary_perf_counters \
    ibex_ternary_debug

# RTL source files
RTL_DIR := ../../rtl
VENDOR_DIR := ../../vendor

RTL_FILES := \
    $(RTL_DIR)/ibex_pkg.sv \
    $(RTL_DIR)/ibex_ternary_alu.sv \
    $(RTL_DIR)/ibex_ternary_regfile.sv \
    $(RTL_DIR)/ibex_ternary_advanced.sv \
    $(RTL_DIR)/ibex_neural_unit.sv \
    $(RTL_DIR)/ibex_neural_unit_enhanced.sv \
    $(RTL_DIR)/ibex_ternary_conv_pool.sv \
    $(RTL_DIR)/ibex_ternary_dma.sv \
    $(RTL_DIR)/ibex_ternary_lsu.sv \
    $(RTL_DIR)/ibex_ternary_perf_counters.sv \
    $(RTL_DIR)/ibex_ternary_debug.sv

# Target frequencies (MHz)
TARGET_FREQ_SLOW := 100
TARGET_FREQ_FAST := 250

# Output directories
BUILD_DIR := build
REPORTS_DIR := reports
NETLIST_DIR := netlist

.PHONY: all clean synth_yosys synth_openlane area timing report

all: synth_yosys report

# Create directories
$(BUILD_DIR) $(REPORTS_DIR) $(NETLIST_DIR):
	mkdir -p $@

# Yosys synthesis (standalone modules)
synth_yosys: $(BUILD_DIR) $(REPORTS_DIR) $(NETLIST_DIR)
	@echo "Running Yosys synthesis..."
	yosys -c synth_ternary.tcl 2>&1 | tee $(REPORTS_DIR)/yosys_synth.log
	@echo "Synthesis complete."

# OpenLane flow (requires Docker)
synth_openlane: $(BUILD_DIR)
	@echo "Running OpenLane synthesis..."
	@if command -v docker &> /dev/null; then \
		docker run --rm -v $(PWD):/work -w /work \
			efabless/openlane:latest \
			flow.tcl -design . -config_file openlane_config.tcl; \
	else \
		echo "Docker not found. Install Docker to run OpenLane."; \
		exit 1; \
	fi

# Generate area report
area: synth_yosys
	@echo "=== Area Report ===" | tee $(REPORTS_DIR)/area_report.txt
	@grep -E "Number of|Area" $(REPORTS_DIR)/yosys_synth.log >> $(REPORTS_DIR)/area_report.txt

# Generate timing report
timing: synth_yosys
	@echo "=== Timing Report ===" | tee $(REPORTS_DIR)/timing_report.txt
	@echo "Target frequency: $(TARGET_FREQ_FAST) MHz" >> $(REPORTS_DIR)/timing_report.txt
	@echo "Target period: $(shell echo "scale=2; 1000/$(TARGET_FREQ_FAST)" | bc) ns" >> $(REPORTS_DIR)/timing_report.txt

# Full report
report: area timing
	@echo ""
	@echo "=== MHX™ Ternary ASIC Synthesis Summary ==="
	@cat $(REPORTS_DIR)/area_report.txt
	@cat $(REPORTS_DIR)/timing_report.txt

# Clean build artifacts
clean:
	rm -rf $(BUILD_DIR) $(REPORTS_DIR) $(NETLIST_DIR)
	rm -f *.json *.blif *.log
