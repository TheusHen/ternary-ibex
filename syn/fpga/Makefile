# MHX™ Ternary Extension - FPGA Synthesis Configuration
# Target: Digilent Arty A7-35T / iCE40 HX8K

# Design configuration
DESIGN_NAME := mhx_ternary_demo
DESIGN_TOP  := mhx_fpga_top

# Target FPGA
FPGA_PART_ARTY := xc7a35ticsg324-1L
FPGA_PART_ICE40 := ice40hx8k-ct256

# RTL source files
RTL_DIR := ../../rtl
FPGA_DIR := .

RTL_FILES := \
    $(RTL_DIR)/ibex_pkg.sv \
    $(RTL_DIR)/ibex_ternary_alu.sv \
    $(RTL_DIR)/ibex_ternary_regfile.sv \
    $(RTL_DIR)/ibex_neural_unit.sv \
    mhx_fpga_top.sv \
    mhx_demo_controller.sv

# Constraint files
XDC_FILES := constraints/arty_a7.xdc
PCF_FILES := constraints/ice40_hx8k.pcf

# Target frequency
TARGET_FREQ := 50  # MHz

# Vivado settings
VIVADO := vivado
VIVADO_MODE := -mode batch

# Yosys/nextpnr for iCE40
YOSYS := yosys
NEXTPNR := nextpnr-ice40
ICEPACK := icepack
ICEPROG := iceprog

# Output directories
BUILD_DIR := build
BIT_DIR := bitstream

.PHONY: all clean arty ice40 program_arty program_ice40

all: arty

# Create directories
$(BUILD_DIR) $(BIT_DIR):
	mkdir -p $@

# Arty A7 synthesis (Vivado)
arty: $(BUILD_DIR) $(BIT_DIR)
	@echo "Synthesizing for Arty A7..."
	$(VIVADO) $(VIVADO_MODE) -source scripts/synth_arty.tcl

# iCE40 synthesis (Yosys + nextpnr)
ice40: $(BUILD_DIR) $(BIT_DIR)
	@echo "Synthesizing for iCE40..."
	$(YOSYS) -p "read_verilog -sv $(RTL_FILES); synth_ice40 -top $(DESIGN_TOP) -json $(BUILD_DIR)/$(DESIGN_NAME).json"
	$(NEXTPNR) --hx8k --package ct256 --pcf $(PCF_FILES) --json $(BUILD_DIR)/$(DESIGN_NAME).json --asc $(BUILD_DIR)/$(DESIGN_NAME).asc
	$(ICEPACK) $(BUILD_DIR)/$(DESIGN_NAME).asc $(BIT_DIR)/$(DESIGN_NAME).bin

# Program Arty A7
program_arty:
	$(VIVADO) $(VIVADO_MODE) -source scripts/program_arty.tcl

# Program iCE40
program_ice40:
	$(ICEPROG) $(BIT_DIR)/$(DESIGN_NAME).bin

# Clean
clean:
	rm -rf $(BUILD_DIR) $(BIT_DIR)
	rm -rf .Xil *.jou *.log *.str
