# Discrepancy Report — Phase 0

**Audit Date:** 2026-11-25  
**Scope:** Cross-check of `Project_Brief.docx`, `Arshad_Ali_Project_Synopsis_With_Schematics-1.docx`, `D:\axi\`, GitHub `Arshad398/AXI_LITEBURST-32_ARSHAD_ALI`, `C:\Users\arsha\Downloads\`, and local host environment.

## 1. Critical Dataset Discrepancy
| Aspect | `Project_Brief.docx` | Project Synopsis (`Arshad_Ali_...docx`) | Actual `dataset.csv` (`C:\Users\arsha\Downloads\dataset.csv`) |
|---|---|---|---|
| **Dataset Type** | AXI transaction log (`trans_id, addr, burst_len, data_width, latency_cycles, error_flag, power_state`) | RISC-V instruction trace (`pc, instruction_hex, opcode, rs1, rs2, rd, cycles_taken, branch_taken, stall`) | RISC-V instruction trace (`pc, instruction_hex, opcode, rs1, rs2, rd, cycles_taken, branch_taken, stall`) |
| **Row Count** | Not fixed (mentions `Dataset_Generation_Prompt.txt`) | Claims **5,000 rows** (e.g., `ADD=982`, `LW=825`, `SW=547`) | **500 data rows** (501 lines incl. header). Actual counts: `ADD=87`, `LW=73`, `SW=58`, `SUB=53`, `BEQ=51`, `AND=50`, `OR=45`, `XOR=37`, `LUI=25`, `JAL=21` |
| **Data Quality** | N/A | Notes `instruction_hex` matches `opcode` in only 2 of 500 rows (synthetic trace) | 0 missing values, 0 duplicate rows, 500 unique rows |
| **Supporting Files** | References `Dataset_Generation_Prompt.txt` (missing) | References `dataset.csv` | `data_dictionary (1).csv` has placeholder `[Learner to fill in description]` |

**Impact:** The supplied `dataset.csv` does **not** match the AXI transaction log schema in `Project_Brief.docx`, and its actual size is **500 rows**, contradicting the **5,000-row** count and opcode table in the synopsis.

## 2. RTL & Architecture Discrepancies
1. **Burst Controller & FSM Disconnected:**
   - Synopsis claims `axi_liteburst32_top.v` integrates `axi_slave_fsm.v`, `burst_controller.v`, and `reg_mem_bank.v` for 1–16 beat bursts.
   - Actual `D:\axi\design\axi_liteburst32_top.v` **does not instantiate** `burst_controller.v`, `axi_slave_fsm.v`, or `reg_mem_bank.v`, has **no burst ports**, and only executes single-beat transfers (confirmed by `Downloads\README.md` / GitHub `README.md`).
2. **Module & Testbench Count Mismatch:**
   - Synopsis Technology Stack claims **11 RTL Modules, 12 Testbenches**.
   - Synopsis Sub-Module Hierarchy lists **14 RTL Modules** (combining `write_data_path.v` and `read_data_path.v` into one bullet).
   - `D:\axi\design\` has **14 `.v` files**; `D:\axi\testbench\` has **13 `.v` files** (`tb_axi_aw_channel.v` is missing despite appearing in a Vivado screenshot tab and README claiming **14 testbenches**).
3. **`DECERR` Response Missing:**
   - Synopsis claims `OKAY, SLVERR, DECERR`, while `response_generator.v` only generates `OKAY` (`2'b00`) and `SLVERR` (`2'b10`).
4. **Low-Power Clock Enable Unused:**
   - `axi_liteburst32_top.v` assigns `wire unused_clock_enable = clock_enable;`, so `low_power_controller` does not actually gate register updates or datapath activity.
5. **Broken `resetn` Connections in Unit Testbenches:**
   - `tb_axi_ar_channel.v`, `tb_axi_b_channel.v`, `tb_axi_r_channel.v`, `tb_axi_slave_fsm.v`, and `tb_axi_w_channel.v` declare `reg resetn=0;` and toggle `resetn=1;`, but **never connect `.resetn(resetn)`** in the DUT port map.

## 3. FPGA Target, Constraints, and Implementation Report Discrepancies
1. **Target Part:** Synopsis mentions Artix-7, Kintex-7, UltraScale+, and ASIC generically without a part number. No `.xpr`, `.tcl`, or `.xdc` exists locally or on GitHub. Vivado screenshots in `D:\axi\Reports\` and `D:\axi\device\` match Zynq-7000 `xc7z020clg400-1` (53,200 LUTs, 106,400 FFs, 125 IOs, 32 BUFGs).
2. **Unconstrained Timing & Power:** Synopsis Timing Summary shows `WNS = inf`, `WHS = inf` with `"There are no user specified timing constraints"`, and Power Report shows **5.2 W** total on-chip power (driven by 3.691 W I/O power with Low Confidence Level) — these cannot be used to claim timing closure.
3. **Authorship Discrepancy in Downloads README:** `C:\Users\arsha\Downloads\README.md` lists Author as `Anuj Bansal`, whereas GitHub `README.md` and the Synopsis list `Arshad Ali`.

## 4. Environment Discrepancies
- Synopsis states **Xilinx Vivado Design Suite 2025.2** and **Python / pandas / scikit-learn** were used.
- On the current local computer, **neither Vivado (nor XSIM/ModelSim/Icarus/Verilator) nor Python is installed**.
