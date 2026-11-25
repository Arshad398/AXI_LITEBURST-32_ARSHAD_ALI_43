# Vivado Tcl: Run Synthesis and Save Reports
open_project vivado_project/AXI_LiteBurst32.xpr
reset_run synth_1
launch_runs synth_1 -jobs 4
wait_on_run synth_1
open_run synth_1
file mkdir reports
report_utilization -file reports/vivado_synth_utilization.rpt
report_timing_summary -file reports/vivado_synth_timing.rpt
report_drc -file reports/vivado_synth_drc.rpt
close_project
