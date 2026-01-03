# MHX™ Ternary Extension - OpenLane Configuration
# Target: Skywater 130nm HD Standard Cells

# Design
set ::env(DESIGN_NAME) "ibex_ternary_alu"
set ::env(VERILOG_FILES) [glob ../../rtl/ibex_pkg.sv ../../rtl/ibex_ternary_alu.sv]

# Clock
set ::env(CLOCK_PORT) "clk_i"
set ::env(CLOCK_PERIOD) "10.0"  ;# 100 MHz
set ::env(CLOCK_NET) $::env(CLOCK_PORT)

# Skywater 130nm PDK
set ::env(PDK) "sky130A"
set ::env(STD_CELL_LIBRARY) "sky130_fd_sc_hd"

# Synthesis
set ::env(SYNTH_STRATEGY) "AREA 0"
set ::env(SYNTH_MAX_FANOUT) 6
set ::env(SYNTH_NO_FLAT) 0

# Floorplanning
set ::env(FP_CORE_UTIL) 40
set ::env(FP_ASPECT_RATIO) 1
set ::env(FP_PDN_CORE_RING) 0
set ::env(FP_PDN_HORIZONTAL_HALO) 6
set ::env(FP_PDN_VERTICAL_HALO) 6

# Placement
set ::env(PL_TARGET_DENSITY) 0.45
set ::env(PL_TIME_DRIVEN) 1
set ::env(PL_BASIC_PLACEMENT) 0

# CTS (Clock Tree Synthesis)
set ::env(CTS_TARGET_SKEW) 200
set ::env(CTS_TOLERANCE) 100

# Routing
set ::env(ROUTING_CORES) 4
set ::env(GLB_RT_MAXLAYER) 5
set ::env(RT_MAX_LAYER) "met4"

# DRC/LVS
set ::env(MAGIC_DRC_USE_GDS) 1
set ::env(RUN_CVC) 1
set ::env(RUN_LVS) 1

# Power
set ::env(VDD_NETS) [list "VPWR" "vccd1"]
set ::env(GND_NETS) [list "VGND" "vssd1"]
set ::env(VDD_PIN) "VPWR"
set ::env(GND_PIN) "VGND"

# Timing
set ::env(STA_REPORT_POWER) 1
set ::env(STA_WRITE_LIB) 1

# Diode insertion
set ::env(DIODE_INSERTION_STRATEGY) 4

# Output
set ::env(GENERATE_FINAL_SUMMARY_REPORT) 1
