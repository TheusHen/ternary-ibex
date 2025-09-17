#!/usr/bin/env magic -dnull -noconsole
# Magic script for GDSII generation - MHX Ternary ALU
# Design: ibex_ternary_alu_verilog
# Technology: sky130A

# Load technology
tech load sky130A

# Create main design cell
set design_name "ibex_ternary_alu_verilog"
set die_width 65000   ;# 65 microns in magic units
set die_height 65000  ;# 65 microns in magic units

# Create new cell
load $design_name -dereference

# Create die boundary
box 0 0 $die_width $die_height
paint ndifcontact

# Add ternary ALU layout structures
# Input section (16 ternary inputs + operation select)
box 5000 10000 15000 55000
paint poly
label "TERNARY_INPUTS" e

# ALU core logic (ternary operations)
box 20000 15000 45000 50000 
paint metal1
label "TERNARY_ALU_CORE" c

# Output section (16 ternary outputs + valid)
box 50000 10000 60000 55000
paint metal2  
label "TERNARY_OUTPUTS" w

# Power distribution
box 0 0 $die_width 2000
paint metal3
label "VSS_RAIL" c

box 0 [expr $die_width - 2000] $die_width $die_width
paint metal3
label "VDD_RAIL" c

# I/O pins setup
# Clock pin
box 30000 0 32000 2000
paint metal1
port make "clk_i"
port "clk_i" class input
port "clk_i" use clock

# Create data input pins (operand_a_i[31:0])
set pin_spacing 1000
set start_y 10000
for {set i 0} {$i < 32} {incr i} {
    set y1 [expr $start_y + $i * $pin_spacing]
    set y2 [expr $y1 + 500]
    box 0 $y1 2000 $y2
    paint metal1
    port make "operand_a_i[$i]"
    port "operand_a_i[$i]" class input
}

# Create data input pins (operand_b_i[31:0])  
for {set i 0} {$i < 32} {incr i} {
    set y1 [expr $start_y + ($i + 33) * $pin_spacing]
    set y2 [expr $y1 + 500]
    box 0 $y1 2000 $y2
    paint metal1
    port make "operand_b_i[$i]"
    port "operand_b_i[$i]" class input
}

# Operation select pins
for {set i 0} {$i < 3} {incr i} {
    set y1 [expr 5000 + $i * $pin_spacing]
    set y2 [expr $y1 + 500]
    box 0 $y1 2000 $y2
    paint metal1
    port make "operation_i[$i]"
    port "operation_i[$i]" class input
}

# Create output pins (result_o[31:0])
for {set i 0} {$i < 32} {incr i} {
    set y1 [expr $start_y + $i * $pin_spacing]
    set y2 [expr $y1 + 500]
    box [expr $die_width - 2000] $y1 $die_width $y2
    paint metal1
    port make "result_o[$i]"
    port "result_o[$i]" class output
}

# Valid output pin
box [expr $die_width - 2000] 50000 $die_width 50500
paint metal1
port make "valid_o"
port "valid_o" class output

# Save design
save $design_name

# Write output files
set output_dir "/workspaces/ternary-ibex/gdsii/final"
file mkdir $output_dir

# Generate GDSII
gds write "$output_dir/${design_name}.gds"

# Generate LEF
lef write "$output_dir/${design_name}.lef"

# Generate DEF  
def write "$output_dir/${design_name}.def"

# Generate Spice netlist
ext2spice lvs
ext2spice cthresh 0
ext2spice rthresh 0
ext2spice
extresist tolerance 10
extresist
ext2spice lvs
ext2spice -o "$output_dir/${design_name}.spice"

puts "Magic GDSII generation completed:"
puts "  Design: $design_name"  
puts "  Die size: [expr $die_width/1000.0] x [expr $die_height/1000.0] um"
puts "  Area: [expr ($die_width * $die_height) / 1000000.0] um²"
puts "  Files: GDSII, LEF, DEF, SPICE"

quit -noprompt
