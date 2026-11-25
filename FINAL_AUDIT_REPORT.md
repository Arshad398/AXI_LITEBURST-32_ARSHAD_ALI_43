# FINAL INDEPENDENT ENGINEERING AUDIT REPORT — AXI-LiteBurst-32

**Audit Date:** 2026-11-25  
**Auditor Role:** Independent Senior FPGA Verification Engineer  
**Scope:** End-to-end reinspection of RTL, testbenches, simulation logs, Vivado scripts/XDC, dataset deliverables, and documentation in `d:\hcl project axi liteburst`.

---

## 1. Independent Verification Summary
| Audit Domain | Result | Evidence Inspected |
|---|---|---|
| RTL Syntax & Elaboration | **PASS** | `iverilog -Wall -g2005 -s axi_liteburst32_top rtl/*.v` → 0 errors, 0 warnings |
| Unit & Integration Simulation | **PASS** | `scripts/run_regression.ps1` → **15/15 PASS**, `tb_axi_liteburst32_top`: **196 checks, 0 errors** (`sim/regression.log`) |
| Custom Burst & Protocol Rules | **PASS** | Verified 1–16 beats, `FIXED`/`INCR`, `WSTRB`, `BREADY`/`RREADY` backpressure stability, early/missing `WLAST`, overflow guard |
| Read/Write Concurrency & Reset | **PASS** | Verified concurrent Bank 0 W + Bank 1 R, same-word write-first arbitration, and mid-burst `resetn=0` recovery |
| Address Protection & Responses | **PASS** | Verified Bank 0/1 isolation, `AxPROT[0]` protection (`SLVERR` + zeroed `RDATA`), and unmapped `DECERR` |
| Low-Power Control | **PASS** | Verified `IDLE_THRESHOLD` idle entry, synchronous `clock_enable` (`CE`) gating, and 0-cycle wake-up |
| Vivado Tcl & XDC Reproducibility | **READY (UNEXECUTED)** | `scripts/*.tcl` and `constraints/axi_liteburst32_xc7z020.xdc` (100 MHz, 122/125 IOs). Not executed locally (Vivado not installed). |
| Dataset & EDA Analytics | **PASS (WITH DISCREPANCY NOTED)** | `dataset/cleaned_dataset.csv` (500 rows), `data_dictionary.csv`, `eda_analysis.py`, `eda_analysis.ipynb`, 4 PNGs |
| Final Documentation | **PASS** | `README.md`, `docs/final_project_report.md` (>8 pages), `docs/demo_script.md`, all Phase 0–8 docs |

---

## 2. Final Requirement-to-Test Traceability Matrix
| Req ID | Requirement | RTL Module(s) | Test Case(s) | Evidence | Status |
|---|---|---|---|---|---|
| REQ-01 | 5-channel AXI4-Lite slave (`AW,W,B,AR,R`) | `axi_*_channel.v`, `axi_liteburst32_top.v` | `TC-01..05,15..17` | `sim/regression.log` (15/15 PASS) | **VERIFIED** |
| REQ-02 | Configurable 32-bit data, param addr/depth | `axi_liteburst32_top.v`, `reg_mem_bank.v` | `TC-26` | `tb_axi_liteburst32_param` PASS | **VERIFIED** |
| REQ-03 | Custom burst extension (1–16 beats, +4) | `burst_controller.v`, `axi_slave_fsm.v` | `TC-06..09,21,22` | `tb_burst_controller` + `tb_axi_liteburst32_top` PASS | **VERIFIED** |
| REQ-04 | Independent R/W concurrency & arbitration | `axi_slave_fsm.v`, `reg_mem_bank.v` | `TC-14` | `tb_axi_slave_fsm` + `tb_axi_liteburst32_top` PASS | **VERIFIED** |
| REQ-05 | Byte-lane write masking (`WSTRB[3:0]`) | `write_data_path.v`, `reg_mem_bank.v` | `TC-10` | `tb_write_data_path` + `tb_axi_liteburst32_top` PASS | **VERIFIED** |
| REQ-06 | Address decode protection & bank isolation | `address_decoder.v`, `read_data_path.v` | `TC-11,22,23` | `tb_address_decoder` + `tb_axi_liteburst32_top` PASS | **VERIFIED** |
| REQ-07 | Deterministic `OKAY`, `SLVERR`, `DECERR` | `response_generator.v`, `axi_slave_fsm.v` | `TC-12,13,18` | `tb_response_generator` + `tb_axi_liteburst32_top` PASS | **VERIFIED** |
| REQ-08 | Low-power idle & synchronous `CE` | `low_power_controller.v`, `reg_mem_bank.v` | `TC-24,25` | `tb_low_power_controller` + `tb_axi_liteburst32_top` PASS | **VERIFIED** |
| REQ-09 | Vivado synthesis & PnR (`xc7z020clg400-1`) | `scripts/*.tcl`, `constraints/*.xdc` | Vivado Batch Flow | Scripts/XDC generated; Vivado not installed locally | **BLOCKED (TOOLING)** |
| REQ-10 | Cleaned dataset, dictionary, 3+ charts | `dataset/*`, `analysis/*` | `eda_analysis.py` | 500-row cleaned CSV, dictionary, 4 PNGs | **VERIFIED (500-ROW TRACE)** |

---

## 3. Open Issue Classification
- **CRITICAL:** None in RTL/Verification. *(Note: `ISS-001` Vivado absence on local host prevents local PnR execution, so physical synthesis/timing closure remains `PENDING VIVADO EXECUTION`.)*
- **HIGH:** `ISS-004` Dataset discrepancy (500-row synthetic RISC-V trace supplied vs. AXI log in Brief / 5,000 rows in Synopsis) — formally documented.
- **MEDIUM:** `ISS-003` No physical board pinout (`LOC`s omitted by design); `analysis/eda_analysis.ipynb` unexecuted due to offline `ipykernel` install SSL error (equivalent `eda_analysis.py` executed cleanly).
- **LOW:** Ethical Compliance Declaration signature line awaits learner wet-ink/digital sign-off.
