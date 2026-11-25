# Verification Report — AXI-LiteBurst-32

**Date:** 2026-11-25  
**Tool Executed:** Icarus Verilog v12.0 (`iverilog -Wall -g2005` + `vvp`)  
**Vivado XSIM Status:** Tcl script `scripts/run_simulation.tcl` generated; XSIM not run locally (Vivado not installed).

## Verification Summary
- **Unit Testbenches:** 13 / 13 PASS (`0` errors).
- **System Integration (`tb_axi_liteburst32_top`):** **PASS** — `196` automated scoreboard/assertion checks, `0` errors.
- **Parameter Variation (`tb_axi_liteburst32_param`):** **PASS** — `ADDR_WIDTH=10, NUM_BANKS=4, BANK_WORDS=16, PROT_BANK_MASK=4'b1100`, `0` errors.
- **Total Regression:** **15 / 15 PASS** (see `reports/regression_report.md` and `sim/regression.log`).
- **Waveform Captured:** `sim/tb_axi_liteburst32_top.vcd` (9,230,000 ps simulation).
