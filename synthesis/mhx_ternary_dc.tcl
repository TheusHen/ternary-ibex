# Design Compiler synthesis script for MHX Ternary Extensions
# For use with Synopsys Design Compiler

# Set up library and constraints
set_app_var target_library "your_target_library.db"
set_app_var link_library "* your_target_library.db"

# Read design files
analyze -format sverilog {
    rtl/ibex_pkg.sv
    rtl/ibex_ternary_regfile.sv
    rtl/ibex_ternary_alu.sv  
    rtl/ibex_neural_unit.sv
}

# Elaborate designs
elaborate ibex_ternary_alu
elaborate ibex_neural_unit
elaborate ibex_ternary_regfile

# Apply synthesis constraints
create_clock -name clk_i -period 10.0 [get_ports clk_i]
set_input_delay -clock clk_i 2.0 [all_inputs]
set_output_delay -clock clk_i 2.0 [all_outputs]

# Synthesize
compile_ultra

# Generate reports
report_area > synthesis/area_report.txt
report_timing > synthesis/timing_report.txt
report_power > synthesis/power_report.txt

# Write netlist
write -format verilog -hierarchy -output synthesis/mhx_ternary_dc_netlist.v

echo "Design Compiler synthesis completed!"
