# Target FPGA: Xilinx Zynq-7000 xc7z020clg400-1 (confirmed by user in Phase 0)
# Target Clock: 100 MHz (10.000 ns period)
# NOTE: Package pin LOC / IOSTANDARD constraints are intentionally omitted because
# no physical board pinout was specified. Do not invent pin mappings.

create_clock -period 10.000 -name sys_clk [get_ports clk]
set_input_delay  -clock sys_clk -max 2.000 [get_ports {resetn s_aw* s_w* s_bready s_ar* s_rready low_power_enable}]
set_input_delay  -clock sys_clk -min 0.500 [get_ports {resetn s_aw* s_w* s_bready s_ar* s_rready low_power_enable}]
set_output_delay -clock sys_clk -max 2.000 [get_ports {s_awready s_wready s_bresp* s_bvalid s_arready s_rdata* s_rresp* s_rlast s_rvalid low_power_idle}]
set_output_delay -clock sys_clk -min 0.500 [get_ports {s_awready s_wready s_bresp* s_bvalid s_arready s_rdata* s_rresp* s_rlast s_rvalid low_power_idle}]
