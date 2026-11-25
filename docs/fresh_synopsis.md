# Project Synopsis — AXI-LiteBurst-32: Configurable AXI4-Lite Slave Interface with Custom Burst Extension

**HCLTech Career Shaper Programme | III Year Industry Project | 2025–26**

| Field | Details |
|---|---|
| **Project Title** | AXI-LiteBurst-32: Configurable AXI4-Lite Slave Interface with Custom Burst Extension |
| **Project No.** | 20 |
| **Domain** | VLSI / RTL Design |
| **Difficulty** | Intermediate |
| **Duration** | 4 Weeks |
| **Format** | Individual Project |
| **Learner Name** | Arshad Ali |
| **Roll Number** | 2400320310043 |
| **College / Campus** | ABES Engineering College, Ghaziabad |
| **Mentor Name** | Mr. Kamal Bhatia |
| **Target FPGA** | Xilinx Zynq-7000 `xc7z020clg400-1` @ 100 MHz |
| **GitHub Repository** | https://github.com/Arshad398/AXI_LITEBURST-32_ARSHAD_ALI |

---

## 1. Problem Statement (5W1H)
Embedded SoC and FPGA engineers (Who) face excessive bus handshake latency when transferring multi-word configuration blocks or status arrays across standard AXI4-Lite slave interfaces (What), particularly in resource-constrained IoT and peripheral subsystems (When/Where). Standard AXI4-Lite lacks native burst support—requiring one address and response handshake per 32-bit word—while full AXI4 adds transaction IDs and reordering logic that increase LUT, flip-flop, and dynamic power overhead (Why). This project solves the problem by designing and verifying **AXI-LiteBurst-32**, a modular 32-bit AXI4-Lite-compatible slave IP with a controlled 1–16 beat custom burst extension, multi-bank `AxPROT[0]` address-decode protection, deterministic error responses, and synchronous low-power clock-enable gating (How).

## 2. Proposed Solution & Approach
AXI-LiteBurst-32 preserves the 5-channel AXI4-Lite architecture (`AW`, `W`, `B`, `AR`, `R`) and introduces an explicit custom burst extension (`s_awlen[3:0]`, `s_awburst[1:0]`, `s_wlast`, `s_arlen[3:0]`, `s_arburst[1:0]`, `s_rlast`) that remains 100% backward-compatible with single-beat transfers when `AxLEN = 0`. A dual concurrent FSM (`axi_slave_fsm`) coordinates independent write and read `burst_controller` engines, allowing simultaneous reads and writes across isolated banks (`reg_mem_bank`) with deterministic write-first same-word collision arbitration. Security is enforced via `address_decoder` and `response_generator` (`OKAY`, `SLVERR`, `DECERR`), while `low_power_controller` drives glitch-free synchronous `clock_enable` (`CE`) gating.

## 3. System Architecture & Module Hierarchy (14 RTL Modules)
1. `axi_liteburst32_top.v` — 122-pin top-level integration wrapper (fits within 125 IOs on `xc7z020clg400-1`)
2. `axi_aw_channel.v` — Write address, burst metadata, and `AWPROT` capture
3. `axi_w_channel.v` — 1-deep streaming `WDATA`, `WSTRB[3:0]`, `WLAST` stage
4. `axi_b_channel.v` — `BRESP`/`BVALID` driver with `BREADY` backpressure stability
5. `axi_ar_channel.v` — Read address, burst metadata, and `ARPROT` capture
6. `axi_r_channel.v` — `RDATA`, `RRESP`, `RLAST`, `RVALID` driver with `RREADY` backpressure stability
7. `burst_controller.v` — Dual-instantiated 1–16 beat engine (`FIXED`/`INCR +4`, 9-bit overflow guard, bank-crossing check)
8. `address_decoder.v` — Dual-instantiated bank/word decoder with alignment, range, and `AxPROT[0]` privilege checks
9. `response_generator.v` — Priority encoder (`DECERR 2'b11` > `SLVERR 2'b10` > `OKAY 2'b00`)
10. `write_data_path.v` — Byte-lane `WSTRB[3:0]` masking and error write suppression
11. `read_data_path.v` — Security zero-masking mux on disallowed/error reads
12. `reg_mem_bank.v` — Configurable `NUM_BANKS × BANK_WORDS × 32-bit` synchronous register bank with `CE`
13. `low_power_controller.v` — Activity monitor, `IDLE_THRESHOLD` counter, synchronous `clock_enable`
14. `axi_slave_fsm.v` — Dual concurrent Write/Read FSM + write-first collision arbiter + `WLAST` error recovery

## 4. Technology Stack
- **HDL:** Verilog-2001 (14 synthesizable RTL modules, 15 self-checking testbenches)
- **Simulation:** Icarus Verilog v12.0 (`iverilog -Wall -g2005` + `vvp`), GTKWave, Vivado XSIM Tcl (`scripts/run_simulation.tcl`)
- **FPGA Automation & Constraints:** Xilinx Vivado Tcl (`scripts/create_fresh_project.tcl`, `run_synthesis.tcl`, `run_implementation.tcl`) + 100 MHz XDC (`constraints/axi_liteburst32_xc7z020.xdc`) targeting `xc7z020clg400-1`
- **Data Analytics:** Python 3.12, pandas, matplotlib, seaborn, Jupyter Notebook

## 5. Dataset Used
- **File:** `dataset/dataset.csv` (500 rows, 9 raw columns; cleaned to `dataset/cleaned_dataset.csv` with 12 columns; 0 missing values, 0 duplicates)
- **Schema:** `pc`, `instruction_hex`, `opcode`, `rs1`, `rs2`, `rd`, `cycles_taken`, `branch_taken`, `stall` (RISC-V instruction trace; note that `Project_Brief.docx` specifies an AXI transaction log and the earlier synopsis template referenced 5,000 rows—this discrepancy is formally documented in `docs/discrepancy_report.md`).
- **Key Measured Statistics:** Overall stall rate = **12.20%** (`61/500`); mean execution latency = **1.540 cycles** (range `1–5`); top opcodes: `ADD` (87, 17.4%), `LW` (73, 14.6%), `SW` (58, 11.6%), `SUB` (53, 10.6%), `BEQ` (51, 10.2%).

## 6. Key Verified Results & Metrics
- **RTL Elaboration:** `0` errors, `0` warnings (`iverilog -Wall -g2005 -s axi_liteburst32_top`).
- **Regression Suite:** **15 / 15 testbenches PASS** (`tb_axi_liteburst32_top`: **196 scoreboard & assertion checks, 0 errors**; `tb_axi_liteburst32_param`: **0 errors**; 13 unit TBs: **0 errors**).
- **Scenario Coverage:** **27 / 27 (100%)** mandatory test scenarios verified, including 16-beat bursts, `WSTRB`, `OKAY`/`SLVERR`/`DECERR`, concurrent R/W + collision, `BREADY`/`RREADY` backpressure, reset-mid-burst, and low-power idle/wake-up.
- **Vivado Synthesis & Implementation:** Reproducible Tcl/XDC scripts prepared for `xc7z020clg400-1` @ 100 MHz (`122 / 125` IOs); execution pending on a Vivado workstation.

## 7. Challenges Faced & Resolutions
1. **Disconnected Baseline Modules →** Integrated `burst_controller`, `axi_slave_fsm`, and `reg_mem_bank` into `axi_liteburst32_top` with full custom burst ports.
2. **8-Bit Address Wrap-Around Risk →** Added 9-bit `addr_overflow` tracking in `burst_controller` so `0xFC` bursts cannot wrap to `0x00` and return `DECERR`.
3. **Read/Write Collision & `WLAST` Deadlock →** Added write-first same-word arbitration and early/missing `WLAST` recovery in `axi_slave_fsm`.
4. **I/O Pin Budget on `xc7z020clg400-1` →** Sized top-level ports to `122 <= 125` package I/Os.

## 8. References
1. ARM Limited, *AMBA AXI and ACE Protocol Specification (AXI3, AXI4, and AXI4-Lite)*, ARM IHI 0022E.
2. AMD Xilinx, *Vivado Design Suite User Guide: Synthesis (UG901)* and *Using Constraints (UG903)*.
3. HCLTech Career Shaper Programme Guidelines, *Project 20: AXI-LiteBurst-32*, Academic Year 2025–26.

## 9. Ethical Compliance Declaration
- [x] All dataset and source code usage complies with open-source and institutional licensing.
- [x] No personally identifiable information (PII) is stored or processed.
- [x] AI tools used for engineering structuring and documentation are disclosed.
- [x] Complies with the DPDP Act 2023 where applicable.
- [x] Implements address decode and `AxPROT[0]` privilege protection against unauthorized register access.

Learner Signature: _________________________ (Arshad Ali) &nbsp;&nbsp;&nbsp;&nbsp; Date: ________________
