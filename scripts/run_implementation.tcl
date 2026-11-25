# Vivado Tcl: Run Implementation (opt, place, route)
open_project vivado_project/AXI_LiteBurst32.xpr
reset_run impl_1
launch_runs impl_1 -jobs 4
wait_on_run impl_1
open_run impl_1
file mkdir reports
report_utilization -file reports/vivado_impl_utilization.rpt
report_timing_summary -file reports/vivado_impl_timing.rpt
report_power -file reports/vivado_impl_power.rpt
report_drc -file reports/vivado_impl_drc.rpt
close_project
