# AXI-LiteBurst-32: Configurable AXI4-Lite Slave Interface with Custom Burst Extension

**HCLTech Career Shaper Programme | Project No. 20 | Academic Year 2025–26**  
**Learner:** Arshad Ali (Roll No: 2400320310043) | **Mentor:** Mr. Kamal Bhatia | **Institution:** ABES Engineering College, Ghaziabad

## Overview
AXI-LiteBurst-32 is a production-quality, synthesizable 32-bit AXI4-Lite-compatible slave IP extended with a controlled custom burst engine supporting 1 to 16 beat transfers (`FIXED` and `INCR`), multi-bank memory isolation (`NUM_BANKS × BANK_WORDS`), `AxPROT[0]` privilege protection, byte-lane write masking (`WSTRB[3:0]`), deterministic error reporting (`OKAY`, `SLVERR`, `DECERR`), and glitch-free synchronous low-power clock-enable management.

## Protocol Boundary Note
Standard AMBA AXI4-Lite does not support native bursts. AXI-LiteBurst-32 preserves the 5-channel AXI4-Lite handshake (`AW`, `W`, `B`, `AR`, `R`) and introduces documented custom burst extension ports (`s_awlen`, `s_awburst`, `s_wlast`, `s_arlen`, `s_arburst`, `s_rlast`) that remain 100% backward-compatible with single-beat transfers when `AxLEN = 0`.

## Directory Structure
- `rtl/` — 14 synthesizable Verilog-2001 RTL modules (`axi_liteburst32_top.v` + 13 sub-modules)
- `tb/` — 15 self-checking Verilog testbenches (13 unit + `tb_axi_liteburst32_top` + `tb_axi_liteburst32_param`)
- `sim/` — Simulation outputs (`regression.log`, `tb_axi_liteburst32_top.vcd`)
- `constraints/` — Vivado timing constraints (`axi_liteburst32_xc7z020.xdc`, 100 MHz)
- `scripts/` — Regression (`run_regression.ps1`) and Vivado Tcl automation (`create_fresh_project.tcl`, `run_simulation.tcl`, `run_synthesis.tcl`, `run_implementation.tcl`, `generate_reports.tcl`)
- `dataset/` — Preserved `dataset.csv`, `cleaned_dataset.csv`, and `data_dictionary.csv`
- `analysis/` — Python EDA script (`eda_analysis.py`), Jupyter notebook (`eda_analysis.ipynb`), and 4 PNG visualizations
- `docs/` & `reports/` — Complete architecture, protocol, verification, EDA, audit, and final project reports
- `backup_original/` — Unmodified backup of original Phase 0 sources

## Quick Verification
- **RTL Regression (Icarus Verilog v12.0):** `powershell -ExecutionPolicy Bypass -File scripts/run_regression.ps1` → **15/15 testbenches PASS**, `tb_axi_liteburst32_top`: **196 checks, 0 errors**.
- **Vivado Batch Flow (on Vivado workstation targeting `xc7z020clg400-1`):**
  ```tcl
  vivado -mode batch -source scripts/create_fresh_project.tcl
  vivado -mode batch -source scripts/run_synthesis.tcl
  vivado -mode batch -source scripts/run_implementation.tcl
  ```
