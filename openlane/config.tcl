# OpenLane Configuration for MHX Ternary ALU
# Copyright 2025 MHX Neural.
# OpenLane flow configuration for SkyWater 130nm ASIC implementation

set ::env(DESIGN_NAME) "ibex_ternary_alu_verilog"

# Design sources
set ::env(VERILOG_FILES) [glob $::env(DESIGN_DIR)/src/*.v]

# Clock configuration  
set ::env(CLOCK_PERIOD) "10.0"  # 100 MHz target
set ::env(CLOCK_PORT) "clk_i"
set ::env(CLOCK_NET) $::env(CLOCK_PORT)

# Technology and PDK
set ::env(PDK) "sky130A"
set ::env(STD_CELL_LIBRARY) "sky130_fd_sc_hd"

# Design flow configuration
set ::env(DESIGN_IS_CORE) 0  # This is a module, not a full chip

# Synthesis configuration
set ::env(SYNTH_STRATEGY) "AREA 0"  # Focus on area optimization
set ::env(SYNTH_MAX_FANOUT) 6
set ::env(SYNTH_BUFFERING) 1
set ::env(SYNTH_SIZING) 1
set ::env(SYNTH_DRIVING_CELL) "sky130_fd_sc_hd__inv_8"

# Floorplan configuration
set ::env(FP_CORE_UTIL) 65      # Core utilization 65%
set ::env(FP_ASPECT_RATIO) 1    # Square aspect ratio
set ::env(FP_PDN_CORE_RING) 0   # No core ring for small module
set ::env(FP_PDN_ENABLE_RAILS) 0

# Placement configuration
set ::env(PL_TARGET_DENSITY) 0.7  # Placement density 70%
set ::env(PL_TIME_DRIVEN) 1       # Enable time-driven placement
set ::env(PL_ROUTABILITY_DRIVEN) 1

# CTS (Clock Tree Synthesis) configuration
set ::env(CTS_TARGET_SKEW) 200     # Target skew 200ps
set ::env(CTS_SINK_CLUSTERING_SIZE) 25
set ::env(CTS_SINK_CLUSTERING_MAX_DIAMETER) 50

# Routing configuration
set ::env(RT_MAX_LAYER) "met4"     # Use up to metal 4
set ::env(ROUTING_STRATEGY) 0      # Default routing strategy
set ::env(GLB_RT_ADJUSTMENT) 0.15
set ::env(GLB_RT_L1_ADJUSTMENT) 0.99
set ::env(GLB_RT_L2_ADJUSTMENT) 0.73
set ::env(GLB_RT_L3_ADJUSTMENT) 0.64

# DRC and LVS configuration
set ::env(DRC_EXCLUDE_CELL_LIST) ""
set ::env(RUN_KLAYOUT_XOR) 1
set ::env(RUN_KLAYOUT_DRC) 1

# Antenna configuration
set ::env(USE_ARC_ANTENNA_CHECK) 1
set ::env(RUN_SPEF_EXTRACTION) 1

# Power analysis
set ::env(RUN_IRDROP_REPORT) 1

# Output configuration
set ::env(MAGIC_WRITE_FULL_LEF) 1
set ::env(RUN_MAGIC_DRC) 1
set ::env(RUN_KLAYOUT) 1

# Custom configuration for ternary ALU
set ::env(SYNTH_READ_BLACKBOX_LIB) 1

# Timing constraints
set ::env(BASE_SDC_FILE) "$::env(DESIGN_DIR)/constraints/timing.sdc"

# Pin configuration (if specific pin placement needed)
set ::env(FP_PIN_ORDER_CFG) "$::env(DESIGN_DIR)/pin_order.cfg"

# Custom scripts
set ::env(EXTRA_LEFS) ""
set ::env(EXTRA_GDS_FILES) ""
set ::env(EXTRA_LIBS) ""

# Regression configuration
set ::env(RUN_CVC) 1

# Debug options
set ::env(DIODE_INSERTION_STRATEGY) 4