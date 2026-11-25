# Vivado Tcl: Generate All Reports from Existing Runs
open_project vivado_project/AXI_LiteBurst32.xpr
file mkdir reports
if {[get_property PROGRESS [get_runs synth_1]] eq "100%"} {
    open_run synth_1
    report_utilization -file reports/vivado_synth_utilization.rpt
    report_timing_summary -file reports/vivado_synth_timing.rpt
}
if {[get_property PROGRESS [get_runs impl_1]] eq "100%"} {
    open_run impl_1
    report_utilization -file reports/vivado_impl_utilization.rpt
    report_timing_summary -file reports/vivado_impl_timing.rpt
    report_power -file reports/vivado_impl_power.rpt
    report_drc -file reports/vivado_impl_drc.rpt
}
close_project
