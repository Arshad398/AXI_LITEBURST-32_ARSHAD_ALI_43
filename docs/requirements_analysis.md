# Requirements Analysis — AXI-LiteBurst-32

**Project:** Project 20 — AXI-LiteBurst-32: Configurable AXI4-Lite Slave Interface with Burst Extension  
**Programme:** HCLTech Career Shaper Programme (2025–26)

## 1. Functional & Architectural Requirements
| ID | Requirement | Source | Current RTL Status (in `D:\axi\design\`) |
|---|---|---|---|
| REQ-01 | 5-channel AXI4-Lite slave architecture (AW, W, B, AR, R) | Brief, Synopsis, Prompt | Implemented in top-level (`axi_aw_channel`, `axi_w_channel`, `axi_b_channel`, `axi_ar_channel`, `axi_r_channel`). |
| REQ-02 | Configurable 32-bit data bus & parameterized address width / memory depth | Prompt, Synopsis | `DATA_WIDTH=32`, `ADDR_WIDTH=8`, `MEM_WORDS=16` parameterized in `axi_liteburst32_top.v`. |
| REQ-03 | Controlled custom burst extension supporting single transfers and 1–16 beat bursts | Brief, Synopsis, Prompt | **GAP:** `burst_controller.v` exists standalone (1–16 beats, 4-byte increment) but is **not instantiated** in `axi_liteburst32_top.v`, and top-level has no burst ports or burst handshake logic. |
| REQ-04 | Independent read and write channel concurrency | Prompt | Single-beat AW/W/B and AR/R operate independently in current top-level; must be preserved when integrating burst support. |
| REQ-05 | Central FSM & register memory bank integration | Synopsis, Prompt | **GAP:** `axi_slave_fsm.v` and `reg_mem_bank.v` exist standalone and are **not instantiated** in `axi_liteburst32_top.v` (top-level uses inline `mem` array). |
| REQ-06 | Byte-lane write masking (`WSTRB[3:0]`) | Synopsis, Prompt | Implemented for single-beat writes in `axi_liteburst32_top.v` and `reg_mem_bank.v`; needs verification across burst beats. |
| REQ-07 | Protected address decoding (alignment + bounds + unauthorized access protection) | Brief §8, Synopsis, Prompt | `address_decoder.v` checks `addr[1:0] == 2'b00` and `addr < MEM_WORDS * 4`. No explicit master/protection (`AWPROT`/`ARPROT`) or bank protection yet. |
| REQ-08 | Deterministic response generation (`OKAY`, `SLVERR`, `DECERR`) | Synopsis, Prompt | **GAP:** `response_generator.v` only produces `OKAY` (`2'b00`) and `SLVERR` (`2'b10`); `DECERR` (`2'b11`) is never generated. |
| REQ-09 | Low-power activity detection and clock-enable management | Brief, Synopsis, Prompt | **GAP:** `low_power_controller.v` computes `idle` and `clock_enable`, but `axi_liteburst32_top.v` ties `clock_enable` to `unused_clock_enable` without gating/enabling registers. |
| REQ-10 | Synchronous active-low reset (`resetn`) across all modules and TBs | Prompt, RTL | **BUG:** 5 unit TBs (`tb_axi_ar_channel`, `tb_axi_b_channel`, `tb_axi_r_channel`, `tb_axi_slave_fsm`, `tb_axi_w_channel`) fail to connect `.resetn(resetn)` to DUT. |

## 2. Verification, EDA, and Deliverable Requirements
| ID | Requirement | Source | Current Status |
|---|---|---|---|
| REQ-11 | Comprehensive self-checking verification (27 scenarios + regression + coverage) | Prompt | **BLOCKED (Tooling):** Vivado XSIM / ModelSim / Icarus Verilog not installed on host; existing TBs lack burst, concurrency, reset-mid-burst, DECERR, and coverage checks. |
| REQ-12 | Reproducible Vivado project (`create_fresh_project.tcl`, synthesis, impl, XDC) | Prompt, Synopsis | **BLOCKED (Tooling & Target):** Vivado not installed on host; no `.xpr`, `.tcl`, or `.xdc` files supplied; target part unconfirmed (screenshots indicate `xc7z020clg400-1`). |
| REQ-13 | Cleaned `dataset.csv`, `data_dictionary.csv`, EDA script/notebook with 3+ charts | Brief, Prompt | **DISCREPANCY:** `dataset.csv` is 500-row RISC-V trace (not AXI log from Brief, and not 5,000 rows from Synopsis); Python not installed on host. |
| REQ-14 | Minimum 8-page individual project report, 1–2 min demo script, Ethical Declaration | Brief, Prompt | Synopsis exists; full 8+ page report and demo script to be generated in Phase 8 after actual results exist. |
