# SkyWater 130nm Timing Constraints for MHX Ternary ALU
# Copyright 2025 MHX Neural.

# Technology specifications for SkyWater 130nm process
# Process: sky130_fd_sc_hd (high density)
# Supply voltage: 1.8V nominal
# Temperature: 25C nominal

# Clock constraints
# Target frequency: 100 MHz for initial implementation
create_clock -name clk -period 10.0 [get_ports clk_i]

# Input delays (assume 2ns from pad to core)
set_input_delay -clock clk -min 1.0 [all_inputs]
set_input_delay -clock clk -max 3.0 [all_inputs]

# Output delays (assume 2ns from core to pad)
set_output_delay -clock clk -min 1.0 [all_outputs]
set_output_delay -clock clk -max 3.0 [all_outputs]

# Operating conditions for SkyWater 130nm
# Worst case: slow-slow corner, 1.62V, 125C
# Best case: fast-fast corner, 1.98V, -40C
# Typical: typical-typical corner, 1.8V, 25C

# Clock uncertainty (jitter + skew)
set_clock_uncertainty 0.5 [get_clocks clk]

# Drive strength (assume medium drive from IO)
set_driving_cell -lib_cell sky130_fd_sc_hd__buf_4 [all_inputs]

# Load constraints (assume typical fanout of 4)
set_load 0.05 [all_outputs]

# False paths (if any combinational-only paths)
# The ternary ALU is purely combinational, so no false paths needed

# Multicycle paths (if any)
# All ternary operations complete in single cycle

# Case analysis (for mode pins if any)
# set_case_analysis 1 [get_ports mode_select]

# Environmental constraints
set_operating_conditions -analysis_type on_chip_variation

# Maximum transition time
set_max_transition 0.5 [current_design]

# Maximum fanout
set_max_fanout 16 [current_design]

# Maximum capacitance
set_max_capacitance 0.2 [current_design]

# Area constraint
# set_max_area 10000

puts "SkyWater 130nm timing constraints loaded successfully"
puts "Target frequency: 100 MHz (10ns period)"
puts "Process: sky130_fd_sc_hd high density standard cells"