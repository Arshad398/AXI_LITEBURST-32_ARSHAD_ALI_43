# AXI-LiteBurst-32: Configurable AXI4-Lite Slave Interface with Custom Burst Extension

**HCLTech Career Shaper Programme — III Year Industry Project (2025–26)**  
**Project Number:** 20 | **Domain:** VLSI / RTL Design | **Level:** Intermediate | **Duration:** 4 Weeks  
**Learner:** Arshad Ali | **Roll Number:** 2400320310043 | **Institution:** ABES Engineering College, Ghaziabad  
**Mentor:** Mr. Kamal Bhatia | **Target FPGA:** Xilinx Zynq-7000 `xc7z020clg400-1` (100 MHz)

---

## 1. Abstract
Modern System-on-Chip (SoC) peripherals require low-area, deterministic register interfaces. While ARM AMBA AXI4-Lite provides a lightweight five-channel control plane, it lacks native burst support, forcing one address and response handshake per 32-bit word during block register initialization or DMA-style transfers. Conversely, full AXI4 introduces transaction IDs, out-of-order completion, and complex reordering buffers that impose unnecessary area and power overhead on compact FPGA and IoT endpoints.

This project designs, implements, and verifies **AXI-LiteBurst-32**, a synthesizable 32-bit AXI4-Lite-compatible slave IP extended with a controlled custom burst engine supporting 1 to 16 beat transfers (`FIXED` and `INCR`), multi-bank register isolation, `AxPROT[0]` privilege protection, byte-lane write masking (`WSTRB[3:0]`), deterministic `OKAY`/`SLVERR`/`DECERR` response generation, and glitch-free synchronous low-power clock-enable management. All 14 RTL modules were elaborated cleanly and verified across 15 self-checking testbenches (196 system-level scoreboard and stability checks, 0 failures) in Icarus Verilog v12.0. Reproducible Vivado Tcl and 100 MHz XDC constraint scripts are provided for `xc7z020clg400-1`, alongside a complete Python EDA pipeline on the supplied 500-row instruction trace dataset.

---

## 2. Introduction
On-chip bus protocols govern communication efficiency, timing closure, and silicon area across processor cores, accelerators, and memory-mapped peripherals. In Xilinx Zynq-7000 and Artix-7 SoC designs, peripheral registers are typically attached to AXI4-Lite interconnects. However, initializing multi-word configuration tables, reading FIFO-mapped windows, or transferring small 16-word blocks over pure AXI4-Lite incurs significant handshake latency.

AXI-LiteBurst-32 addresses this architectural gap by preserving the standard 5-channel AXI4-Lite interface (`AW`, `W`, `B`, `AR`, `R`) while adding an explicit, documented custom burst extension (`AxLEN[3:0]`, `AxBURST[1:0]`, `WLAST`, `RLAST`) that remains 100% backward-compatible with single-beat transfers when `AxLEN = 0`.

---

## 3. Problem Statement
Embedded SoC designers (Who) face excessive bus handshake overhead and latency when performing multi-word register transfers over standard AXI4-Lite interfaces (What), particularly in resource-constrained FPGA and IoT peripheral subsystems during block configuration and status bursts (When/Where). Standard AXI4-Lite lacks native burst support, while full AXI4 incurs excessive LUT, flip-flop, and power overhead, and naive slave implementations risk unauthorized register access or read/write collisions (Why). This project solves the problem by architecting a modular, concurrent 32-bit AXI4-Lite-compatible slave IP with a 1–16 beat custom burst extension, address-decode privilege protection, deterministic error responses, and synchronous low-power clock-enable control (How).

---

## 4. Objectives
1. Implement an independent five-channel AXI slave architecture (`AW`, `W`, `B`, `AR`, `R`) with true read/write concurrency.
2. Introduce a well-defined custom burst extension supporting 1–16 beats (`FIXED` and `INCR` +4-byte stride) while maintaining single-beat AXI4-Lite compatibility.
3. Provide parameterized multi-bank 32-bit register storage (`NUM_BANKS × BANK_WORDS`) with bank isolation and byte-lane `WSTRB[3:0]` masking.
4. Enforce address-decode and `AxPROT[0]` privilege protection with deterministic `OKAY`, `SLVERR`, and `DECERR` responses and zero-masked error reads.
5. Implement glitch-free synchronous low-power activity monitoring and `clock_enable` (`CE`) gating.
6. Validate all 27 required verification scenarios via self-checking testbenches, prepare reproducible Vivado Tcl/XDC automation, and complete the HCL dataset EDA deliverables.

---

## 5. Existing Protocol Limitations & Custom Burst Boundary
Per the ARM AMBA AXI and ACE Protocol Specification (IHI 0022E), **standard AXI4-Lite does not support burst transactions** and omits `AxLEN`, `AxSIZE`, `AxBURST`, `WLAST`, and `RLAST`. Therefore, AXI-LiteBurst-32 explicitly classifies its multi-beat capability as a **custom burst extension** on top of AXI4-Lite:
- **Single-Beat Compatibility:** Setting `s_awlen = 4'd0`, `s_awburst = 2'b01`, `s_wlast = 1'b1`, `s_arlen = 4'd0`, `s_arburst = 2'b01` executes standard 1-beat AXI4-Lite transfers.
- **Custom Burst Signals:** `s_awlen[3:0]` / `s_arlen[3:0]` encode `1..16` beats (`LEN + 1`); `s_awburst[1:0]` / `s_arburst[1:0]` select `FIXED (2'b00)` or `INCR (2'b01)`; `s_wlast` terminates write bursts; `s_rlast` terminates read bursts.

---

## 6. Proposed Solution & System Architecture
### 6.1 Architectural Audit & Baseline Remediation
Inspection of the initial Phase 0 repository (`D:\axi\design\`) revealed critical gaps: `burst_controller.v`, `axi_slave_fsm.v`, and `reg_mem_bank.v` were standalone and uninstantiated in `axi_liteburst32_top.v`, no burst ports existed, `DECERR` was unimplemented, `clock_enable` was tied to an unused wire, and 5 unit testbenches omitted `.resetn(resetn)`. The Phase 1/2 architecture resolves every one of these gaps by integrating all 14 modules into a unified concurrent design.

### 6.2 Module Hierarchy (14 Synthesizable Modules)
| # | Module | Role |
|---|---|---|
| 1 | `axi_liteburst32_top` | 122-pin top-level integration wrapper |
| 2 | `axi_aw_channel` | Write address, burst metadata, and `AWPROT` capture |
| 3 | `axi_w_channel` | 1-deep streaming `WDATA`, `WSTRB`, `WLAST` capture |
| 4 | `axi_b_channel` | `BRESP` / `BVALID` register with `BREADY` backpressure hold |
| 5 | `axi_ar_channel` | Read address, burst metadata, and `ARPROT` capture |
| 6 | `axi_r_channel` | `RDATA`, `RRESP`, `RLAST`, `RVALID` driver with `RREADY` hold |
| 7 | `burst_controller` | Dual-instantiated 1–16 beat engine with overflow & bank-cross guards |
| 8 | `address_decoder` | Dual-instantiated bank/word decoder with alignment & `AxPROT[0]` check |
| 9 | `response_generator` | Priority encoder (`DECERR > SLVERR > OKAY`) |
| 10 | `write_data_path` | `WSTRB[3:0]` lane conditioning and error write suppression |
| 11 | `read_data_path` | Security zero-masking mux on disallowed/error reads |
| 12 | `reg_mem_bank` | Configurable `NUM_BANKS × BANK_WORDS × 32-bit` synchronous array with `CE` |
| 13 | `low_power_controller` | Activity monitor, `IDLE_THRESHOLD` counter, synchronous `clock_enable` |
| 14 | `axi_slave_fsm` | Dual concurrent Write/Read FSM + write-first collision arbiter |

### 6.3 Concurrency & Arbitration
Unlike single-FSM designs that serialize reads and writes, `axi_slave_fsm` runs independent Write (`W_IDLE → W_BURST → W_RESP`) and Read (`R_IDLE → R_BURST → R_WAIT_LAST`) state machines. Reads and writes targeting different words or banks execute simultaneously in the same clock cycle. When both target the exact same `(bank, word_index)` on the same cycle, **write-first collision arbitration** grants `wr_mem_en` immediately and holds `rd_mem_en` for one cycle so the read deterministically observes the updated word.

---

## 7. RTL Implementation Details
### 7.1 Register Map & Address Protection
With default parameters (`ADDR_WIDTH=8`, `NUM_BANKS=2`, `BANK_WORDS=16`, `PROT_BANK_MASK=2'b10`):
- **`0x00 .. 0x3F` (Bank 0, 16 words):** Open R/W register bank supporting 1–16 beat bursts.
- **`0x40 .. 0x7F` (Bank 1, 16 words):** Privileged-only register bank requiring `AxPROT[0] == 1`. Unprivileged accesses return `SLVERR (2'b10)`, suppress writes, and force `s_rdata = 32'h0000_0000`.
- **`0x80 .. 0xFF` (Unmapped, 128 bytes):** Returns `DECERR (2'b11)`. A 9-bit internal address adder in `burst_controller` prevents 8-bit wrap-around from `0xFC` back into `0x00`.

### 7.2 Burst Error & `WLAST` Handling
- **Unsupported Burst Type (`2'b10`/`2'b11`), Unaligned Address (`addr[1:0]!=0`), Bank-Crossing Burst:** Flagged as `SLVERR (2'b10)`.
- **Early/Missing `WLAST`:** If `s_wlast` asserts early (`!wr_last && wlast_q`), the write FSM latches sticky `SLVERR`, aborts `u_wr_burst`, and transitions cleanly to `W_RESP` to prevent bus deadlock. Missing `s_wlast` on the final expected beat also latches `SLVERR`.

### 7.3 Low-Power Architecture
`low_power_controller` monitors all 5 channels and FSM active states. After `IDLE_THRESHOLD` (default `8`) consecutive idle cycles with `low_power_enable == 1`, `low_power_idle` asserts and `clock_enable` de-asserts. Because `clock_enable = !idle || activity || !enable` is wired to the synchronous `CE` gate of `reg_mem_bank`, Xilinx 7-series flip-flops gate updates without introducing clock-tree glitches, and any incoming `VALID` wakes the interface in zero clock cycles.

---

## 8. Verification Methodology & Simulation Results
### 8.1 Verification Environment
All 14 RTL modules were compiled and elaborated with strict linting (`iverilog -Wall -g2005`) with zero errors and zero warnings. A 15-testbench regression suite (`scripts/run_regression.ps1`) was executed in Icarus Verilog v12.0:
- **13 Unit Testbenches:** Verify every leaf module independently (`tb_address_decoder`, `tb_axi_ar_channel`, `tb_axi_aw_channel`, `tb_axi_b_channel`, `tb_axi_r_channel`, `tb_axi_slave_fsm`, `tb_axi_w_channel`, `tb_burst_controller`, `tb_low_power_controller`, `tb_read_data_path`, `tb_reg_mem_bank`, `tb_response_generator`, `tb_write_data_path`).
- **System Integration Testbench (`tb_axi_liteburst32_top`):** Uses a golden 32-word reference scoreboard (`ref_mem`), protocol backpressure stability assertions, and randomized burst stress testing across scenarios `TC-01..25` and `TC-27`.
- **Parameter Variation Testbench (`tb_axi_liteburst32_param`):** Verifies `TC-26` with `ADDR_WIDTH=10`, `NUM_BANKS=4`, `BANK_WORDS=16`, `PROT_BANK_MASK=4'b1100`, `IDLE_THRESHOLD=4`.

### 8.2 Actual Observed Simulation Results
| Metric | Observed Result |
|---|---|
| Testbenches Executed | **15 / 15 PASS** (`0` failures) |
| `tb_axi_liteburst32_top` Scoreboard Checks | **196 checks, 0 errors** (9,230 ns simulation) |
| Mandatory Scenario Coverage | **27 / 27 (100%)** |
| Waveform Artifact | `sim/tb_axi_liteburst32_top.vcd` |

---

## 9. Vivado Synthesis, Implementation & Resource Status
### 9.1 Reproducible Automation & Constraints
To ensure portability to a Vivado workstation targeting `xc7z020clg400-1`, the project includes:
- `scripts/create_fresh_project.tcl`, `scripts/run_simulation.tcl`, `scripts/run_synthesis.tcl`, `scripts/run_implementation.tcl`, `scripts/generate_reports.tcl`
- `constraints/axi_liteburst32_xc7z020.xdc` defining a **100 MHz (`10.000 ns`)** clock constraint and `2.000 ns` max / `0.500 ns` min I/O delays without inventing physical board `PACKAGE_PIN` mappings.
- **I/O Pin Budget:** Top-level port count is **122 I/O pins**, fitting within the `125` available user I/Os of `xc7z020clg400-1`.

### 9.2 Execution Status vs. Historical Baseline
Because Xilinx Vivado is **not installed** on the current host PC, synthesis and implementation of the Phase 2 burst-enabled RTL are **PENDING VIVADO EXECUTION** (no Vivado netlist numbers are fabricated). For historical comparison only, the Phase 0 unconstrained single-beat baseline screenshots (`D:\axi\Reports\`) recorded `263` LUTs (`0.49%`), `612` FFs (`0.58%`), `110` IOs (`88.00%`), `1` BUFG (`3.13%`), and `WNS = inf` (unconstrained).

---

## 10. Dataset & Exploratory Data Analysis
### 10.1 Dataset Discrepancy Audit
While `Project_Brief.docx` references an AXI transaction log (`trans_id, addr, burst_len, data_width, latency_cycles, error_flag, power_state`) and the Synopsis describes a 5,000-row trace, the actual supplied `dataset.csv` is a **500-row, 9-column RISC-V instruction trace** (`pc, instruction_hex, opcode, rs1, rs2, rd, cycles_taken, branch_taken, stall`) with **0 missing values** and **0 duplicates**.

### 10.2 Measured EDA Findings (`analysis/eda_analysis.py`)
- **Instruction Mix:** `ALU` (`59.4%`), `Memory` (`26.2%`), `Control` (`14.4%`). Most frequent opcode: `ADD` (`87` rows, `17.4%`), followed by `LW` (`73`, `14.6%`) and `SW` (`58`, `11.6%`).
- **Stall Rate:** Overall `12.20%` (`61/500`); highest in `SW` (`17.24%`), `SUB` (`16.98%`), and `LUI` (`16.00%`); lowest in `LW` (`5.48%`).
- **Execution Latency:** Mean `1.540` cycles (median `1.0`, range `1–5`); `JAL` has the highest mean latency (`1.86` cycles).
- **Trace Provenance:** Non-control opcodes exhibit non-zero `branch_taken` rates (`13.79%–26.42%`), confirming the trace is synthetically generated.
- **Deliverables Generated:** `dataset/cleaned_dataset.csv` (12 columns), `dataset/data_dictionary.csv`, `analysis/eda_analysis.py`, `analysis/eda_analysis.ipynb`, and 4 visualizations in `analysis/visualizations/`.

---

## 11. Challenges and Solutions
1. **Disconnected Burst & FSM Modules in Baseline:** Re-architected `axi_liteburst32_top.v` to instantiate dual `burst_controller` engines, `axi_slave_fsm`, and `reg_mem_bank` with full burst handshakes.
2. **8-Bit Address Wrap-Around Security Risk:** Added a 9-bit extended adder (`addr_overflow`) in `burst_controller.v` so bursts near `0xFC` cannot wrap into `0x00` and instead return `DECERR`.
3. **Read/Write Collision & `WLAST` Deadlock:** Implemented write-first same-word collision arbitration and early/missing `WLAST` error recovery in `axi_slave_fsm.v`.
4. **I/O Pin Budget on `xc7z020clg400-1`:** Parameterized `IDLE_THRESHOLD` cleanly to keep top-level I/O count at `122 <= 125` package pins.

---

## 12. Conclusion
AXI-LiteBurst-32 delivers a complete, modular, 14-module AXI4-Lite-compatible slave IP with a 1–16 beat custom burst extension, multi-bank privilege protection, deterministic `OKAY`/`SLVERR`/`DECERR` responses, and glitch-free synchronous low-power control. Functional correctness is proven across 15/15 passing simulations (196 system checks, 0 errors), and the project is fully packaged with Vivado Tcl/XDC automation and verified Python EDA deliverables.

---

## 13. References
1. ARM Limited, *AMBA AXI and ACE Protocol Specification (AXI3, AXI4, and AXI4-Lite)*, ARM IHI 0022E.
2. AMD Xilinx, *Vivado Design Suite User Guide: Synthesis (UG901)* and *Using Constraints (UG903)*.
3. HCLTech Career Shaper Programme, *Project 20: AXI-LiteBurst-32 Project Brief & Guidelines*, Academic Year 2025–26.

---

## 14. Ethical Compliance Declaration
I confirm that:
- [x] All dataset and source code usage complies with open-source and institutional licensing.
- [x] No personally identifiable information (PII) is stored or processed.
- [x] AI engineering tools used for RTL structuring, verification, and documentation are disclosed.
- [x] This project complies with applicable digital data protection standards (DPDP Act 2023).
- [x] The AXI slave implements address decode and `AxPROT[0]` privilege protection to prevent unauthorized register access.

Learner Signature: _________________________ (Arshad Ali) &nbsp;&nbsp;&nbsp;&nbsp; Date: ________________
