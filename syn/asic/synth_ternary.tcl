# MHX™ Ternary Extension - Yosys Synthesis Script
# Target: Generic (area estimation) and Skywater 130nm
# Copyright 2025 MHX™ Neural

puts "========================================"
puts "MHX™ Ternary Extension - Yosys Synthesis"
puts "========================================"

# Design parameters
set design_name "mhx_ternary_modules"
set rtl_dir "../../rtl"
set vendor_dir "../../vendor"

# Create output directories
file mkdir build
file mkdir reports
file mkdir netlist

# Read RTL files
puts "\n=== Reading RTL files ==="

# Read package first
read_verilog -sv $rtl_dir/ibex_pkg.sv

# Read ternary modules
set ternary_modules {
    ibex_ternary_alu
    ibex_ternary_regfile
    ibex_ternary_advanced
    ibex_neural_unit
    ibex_neural_unit_enhanced
    ibex_ternary_conv_pool
    ibex_ternary_dma
    ibex_ternary_lsu
    ibex_ternary_perf_counters
    ibex_ternary_debug
}

foreach module $ternary_modules {
    puts "Reading $module..."
    read_verilog -sv $rtl_dir/${module}.sv
}

puts "\n=== Synthesizing Individual Modules ==="

# Synthesize each module separately for area analysis
set total_cells 0
set total_area 0

foreach module $ternary_modules {
    puts "\n--- Synthesizing $module ---"
    
    # Hierarchy processing
    hierarchy -check -top $module
    
    # Technology mapping (generic)
    proc
    flatten
    opt -full
    
    # FSM extraction and optimization
    fsm
    opt
    
    # Memory mapping
    memory -nomap
    opt
    
    # Techmap to generic cells
    techmap
    opt
    
    # ABC optimization for area
    abc -liberty $vendor_dir/lowrisc_ip/ip/prim_generic/prim_generic.lib \
        -D 10000 || abc
    
    # Clean up
    clean
    opt_clean
    
    # Generate statistics
    puts "\nStatistics for $module:"
    tee -o reports/${module}_stats.txt stat
    
    # Write netlist
    write_verilog netlist/${module}_synth.v
    write_json netlist/${module}_synth.json
    
    # Reset for next module
    design -reset
    read_verilog -sv $rtl_dir/ibex_pkg.sv
    read_verilog -sv $rtl_dir/${module}.sv
}

puts "\n=== Combined Ternary Extension Synthesis ==="

# Read all files again for combined synthesis
design -reset
read_verilog -sv $rtl_dir/ibex_pkg.sv

foreach module $ternary_modules {
    read_verilog -sv $rtl_dir/${module}.sv
}

# Synthesize with ibex_ternary_alu as representative top
hierarchy -check -top ibex_ternary_alu
proc
flatten
opt -full
techmap
abc
clean

puts "\n=== Final Statistics ==="
tee -o reports/combined_stats.txt stat

# Write combined netlist
write_verilog netlist/mhx_ternary_combined.v
write_json netlist/mhx_ternary_combined.json

puts "\n=== Synthesis Complete ==="
puts "Reports saved to: reports/"
puts "Netlists saved to: netlist/"
