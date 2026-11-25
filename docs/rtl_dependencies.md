# RTL Dependencies & Synthesis Guidelines — AXI-LiteBurst-32

## 1. Compilation Order (Bottom-Up Dependency Graph)
All 14 modules are pure synthesizable Verilog-2001 (`rtl/*.v`) with zero simulation-only constructs (`$display`, `#delay`, `initial` blocks for synthesis registers):

1. `rtl/address_decoder.v` (leaf)
2. `rtl/response_generator.v` (leaf)
3. `rtl/reg_mem_bank.v` (leaf)
4. `rtl/write_data_path.v` (leaf)
5. `rtl/read_data_path.v` (leaf)
6. `rtl/axi_aw_channel.v` (leaf)
7. `rtl/axi_w_channel.v` (leaf)
8. `rtl/axi_b_channel.v` (leaf)
9. `rtl/axi_ar_channel.v` (leaf)
10. `rtl/axi_r_channel.v` (leaf)
11. `rtl/burst_controller.v` (leaf)
12. `rtl/low_power_controller.v` (leaf)
13. `rtl/axi_slave_fsm.v` (leaf)
14. `rtl/axi_liteburst32_top.v` (top-level integration wrapper instantiating modules 1–13)

## 2. Coding & Synthesizability Compliance
- **Latches:** Zero inferred latches; all combinational `always @(*)` blocks assign complete default values (`axi_slave_fsm.v`, `response_generator.v`).
- **Clocking & Reset:** Single global synchronous `posedge clk`, active-low synchronous `resetn` across every sequential module.
- **Low-Power Clock Enable:** `low_power_controller` generates glitch-free `clock_enable = !idle || activity || !enable`, connected to the synchronous write-enable / CE gate in `reg_mem_bank` (maps directly to Xilinx 7-series FF `CE` pins without clock-tree gating).
- **X/Z Prevention:** Every register initializes deterministically under `!resetn`, and `read_data_path` forces `32'h0000_0000` on disallowed/error reads.
