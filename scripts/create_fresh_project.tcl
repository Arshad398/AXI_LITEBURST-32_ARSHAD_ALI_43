# Vivado Tcl: Create Fresh Project for AXI-LiteBurst-32
set proj_name "AXI_LiteBurst32"
set proj_dir  "vivado_project"
set part_name "xc7z020clg400-1"

file mkdir $proj_dir
create_project $proj_name $proj_dir -part $part_name -force

# Add synthesizable RTL sources (sources_1)
add_files -fileset sources_1 [glob rtl/*.v]
set_property top axi_liteburst32_top [get_filesets sources_1]

# Add simulation testbenches (sim_1)
add_files -fileset sim_1 [glob tb/*.v]
set_property top tb_axi_liteburst32_top [get_filesets sim_1]

# Add timing constraints
add_files -fileset constrs_1 constraints/axi_liteburst32_xc7z020.xdc

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
puts "INFO: Created Vivado project $proj_name for part $part_name"
