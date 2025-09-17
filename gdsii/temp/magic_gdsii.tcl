#!/usr/bin/env magic -dnull -noconsole
# Magic script for GDSII generation
# Design: ibex_ternary_alu_verilog
# Technology: sky130A

# Load technology
tech load sky130A

# Set up design
set design_name "ibex_ternary_alu_verilog"
set output_dir "/workspaces/ternary-ibex/gdsii/final"

# Create a simple layout for the ternary ALU
# This is a demonstration layout - in practice, this would come from OpenLane

# Create the main cell
magic::suspendall
load $design_name -dereference

# Define the die area (65um x 65um based on our floorplan)
set die_width 65000  ;# in magic units (1um = 1000 units)
set die_height 65000

# Create die boundary
box 0 0 $die_width $die_height
paint ndifcontact

# Add some demo structures for visualization
# This represents the ternary ALU logic blocks

# Input section (left side)
box 5000 10000 15000 55000
paint poly
label "INPUT_SECTION" e

# ALU core (center)
box 20000 15000 45000 50000
paint metal1
label "ALU_CORE" c

# Output section (right side)  
box 50000 10000 60000 55000
paint metal2
label "OUTPUT_SECTION" w

# Add power rails
box 0 0 $die_width 2000
paint metal3
label "VSS" c

box 0 [expr $die_height - 2000] $die_width $die_height
paint metal3
label "VDD" c

# Add pin locations
# Clock pin
box 30000 0 32000 2000
paint metal1
port make "clk_i"
port "clk_i" class input
port "clk_i" use clock

# Data input pins (left edge)
set pin_y 10000
for {set i 0} {$i < 32} {incr i} {
    set y1 [expr $pin_y + $i * 1000]
    set y2 [expr $y1 + 500]
    box 0 $y1 2000 $y2
    paint metal1
    port make "operand_a_i[$i]"
    port "operand_a_i[$i]" class input
}

# Operation select pins
for {set i 0} {$i < 3} {incr i} {
    set y1 [expr 45000 + $i * 1000]
    set y2 [expr $y1 + 500]
    box 0 $y1 2000 $y2
    paint metal1
    port make "operation_i[$i]"
    port "operation_i[$i]" class input
}

# Output pins (right edge)
for {set i 0} {$i < 32} {incr i} {
    set y1 [expr 10000 + $i * 1000]
    set y2 [expr $y1 + 500]
    box [expr $die_width - 2000] $y1 $die_width $y2
    paint metal1
    port make "result_o[$i]"
    port "result_o[$i]" class output
}

# Valid output pin
box [expr $die_width - 2000] 45000 $die_width 45500
paint metal1
port make "valid_o"
port "valid_o" class output

# Save as Magic format
save $design_name

# Generate GDSII
gds write "$output_dir/${design_name}.gds"

# Generate LEF
lef write "$output_dir/${design_name}.lef"

# Generate DEF
def write "$output_dir/${design_name}.def"

# Report statistics
set cell_count [expr [llength [cellname list self]] - 1]
set area [expr $die_width * $die_height / 1000000.0]

puts "GDSII Generation Complete:"
puts "  Design: $design_name"
puts "  Technology: sky130A"
puts "  Die size: [expr $die_width/1000.0]um x [expr $die_height/1000.0]um"
puts "  Area: $area um²"
puts "  Files generated:"
puts "    - $output_dir/${design_name}.gds"
puts "    - $output_dir/${design_name}.lef"  
puts "    - $output_dir/${design_name}.def"

magic::suspendall
quit -noprompt
