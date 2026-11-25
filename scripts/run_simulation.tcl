# Vivado Tcl: Run Behavioral Simulation (XSIM)
open_project vivado_project/AXI_LiteBurst32.xpr
set_property top tb_axi_liteburst32_top [get_filesets sim_1]
launch_simulation
run all
close_sim
close_project
