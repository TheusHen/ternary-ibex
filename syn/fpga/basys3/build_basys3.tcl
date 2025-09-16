# Vivado synthesis script for MHX Simple System on Basys3

# Set project properties
set project_name "mhx_basys3"
set part_name "xc7a35tcpg236-1"

# Create project
create_project $project_name ./$project_name -part $part_name -force

# Add source files
set rtl_root "../../../"

# Add Ibex core files
add_files [glob ${rtl_root}/rtl/*.sv]

# Add MHX system files
add_files [glob ${rtl_root}/examples/mhx_simple_system/rtl/*.sv]

# Add shared simulation files
add_files [glob ${rtl_root}/shared/rtl/*.sv]

# Add vendor IP files (lowRISC)
add_files [glob ${rtl_root}/vendor/lowrisc_ip/ip/prim/rtl/*.sv]
add_files [glob ${rtl_root}/vendor/lowrisc_ip/ip/prim_generic/rtl/*.sv]

# Add FPGA top-level
add_files ../common/mhx_fpga_top.sv

# Add constraints
add_files -fileset constrs_1 basys3.xdc

# Set top module
set_property top mhx_fpga_top [current_fileset]

# Create clock wizard IP
create_ip -name clk_wiz -vendor xilinx.com -library ip -version 6.0 -module_name clk_wiz_0
set_property -dict [list CONFIG.PRIM_IN_FREQ {100.000} \
                         CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {50.000} \
                         CONFIG.USE_LOCKED {true} \
                         CONFIG.USE_RESET {true} \
                         CONFIG.RESET_TYPE {ACTIVE_HIGH} \
                         CONFIG.RESET_PORT {reset}] [get_ips clk_wiz_0]
generate_target all [get_ips clk_wiz_0]

# Update compile order
update_compile_order -fileset sources_1

# Run synthesis
launch_runs synth_1 -jobs 4
wait_on_run synth_1

# Check for synthesis errors
if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
    error "Synthesis failed"
}

# Run implementation
launch_runs impl_1 -jobs 4
wait_on_run impl_1

# Check for implementation errors
if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
    error "Implementation failed"
}

# Generate bitstream
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

# Check for bitstream generation
if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
    error "Bitstream generation failed"
}

# Export hardware
write_hw_platform -fixed -include_bit -force -file ./${project_name}/${project_name}.xsa

puts "MHX Basys3 build completed successfully!"
puts "Bitstream: ./${project_name}/${project_name}.runs/impl_1/mhx_fpga_top.bit"
puts "Hardware platform: ./${project_name}/${project_name}.xsa"