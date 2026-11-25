# Project Inventory — AXI-LiteBurst-32

**Workspace:** `d:\hcl project axi liteburst`  
**Audit Date:** 2026-11-25  
**Phase:** Phase 0 — Environment Discovery and Project Audit

## 1. Authoritative Source Locations Discovered
1. **Working Directory (Initially Empty):** `d:\hcl project axi liteburst`
   - Backed up original sources into `d:\hcl project axi liteburst\backup_original\` without modifying original external folders.
2. **Existing Project Folder (`D:\axi`):**
   - Matches GitHub repository `https://github.com/Arshad398/AXI_LITEBURST-32_ARSHAD_ALI` (`main` branch, 5 commits, latest commit `0febc9c` on `2026-11-20T10:41:13Z`).
   - `design/` — 14 Verilog (`.v`) files:
     - `axi_liteburst32_top.v` (5,497 bytes, 121 lines)
     - `axi_slave_fsm.v` (656 bytes, 18 lines)
     - `axi_aw_channel.v` (631 bytes, 18 lines)
     - `axi_w_channel.v` (752 bytes, 21 lines)
     - `axi_b_channel.v` (504 bytes, 16 lines)
     - `axi_ar_channel.v` (631 bytes, 18 lines)
     - `axi_r_channel.v` (666 bytes, 19 lines)
     - `burst_controller.v` (1,495 bytes, 45 lines)
     - `address_decoder.v` (434 bytes, 13 lines)
     - `write_data_path.v` (298 bytes, 9 lines)
     - `read_data_path.v` (185 bytes, 6 lines)
     - `reg_mem_bank.v` (1,126 bytes, 33 lines)
     - `low_power_controller.v` (827 bytes, 28 lines)
     - `response_generator.v` (177 bytes, 6 lines)
   - `testbench/` — 13 Verilog (`.v`) testbenches:
     - `tb_axi_liteburst32_top.v` (4,809 bytes, 103 lines)
     - `tb_address_decoder.v` (440 bytes)
     - `tb_axi_ar_channel.v` (789 bytes)
     - `tb_axi_b_channel.v` (750 bytes)
     - `tb_axi_r_channel.v` (926 bytes)
     - `tb_axi_slave_fsm.v` (938 bytes)
     - `tb_axi_w_channel.v` (910 bytes)
     - `tb_burst_controller.v` (1,066 bytes)
     - `tb_low_power_controller.v` (802 bytes)
     - `tb_read_data_path.v` (357 bytes)
     - `tb_reg_mem_bank.v` (987 bytes)
     - `tb_response_generator.v` (397 bytes)
     - `tb_write_data_path.v` (474 bytes)
     - Note: `tb_axi_aw_channel.v` is referenced in `schematics/WhatsApp Image 2026-11-20 at 11.58.50 AM (4).jpeg` Vivado tab and README ("14 Verilog testbenches") but is **missing** from `D:\axi\testbench\` and GitHub.
   - `device/` — 1 JPEG (`WhatsApp Image 2026-11-20 at 12.00.13 PM.jpeg`, Vivado post-implementation floorplan showing Zynq-7000 die geometry with PS7 cutout on `X0Y1`/`X0Y2`).
   - `Reports/` — 3 JPEGs (`Timing Summary`, `Utilization Post-Implementation`, `On-Chip Power`).
   - `schematics/` — 14 JPEGs (Vivado elaborated RTL schematics).
   - `simulation/` — 14 JPEGs (Vivado XSim waveform captures).
   - `README.md` — 18 bytes (`# AXI_LITEBURST-32`), whereas GitHub `README.md` is 3,531 bytes.
   - **Missing from `D:\axi` and GitHub:** `.xpr` Vivado project file, `.tcl` automation scripts, `.xdc` constraint files, text-based Vivado synthesis/implementation/timing/utilization reports, and simulation logs.
3. **Synopsis Document (`D:\ar\Arshad_Ali_Project_Synopsis_With_Schematics-1.docx`):**
   - 2,665,763 bytes (also zipped inside `C:\Users\arsha\Downloads\Files.zip`).
   - Learner: Arshad Ali, Roll No: 2400320310043, College: ABES Engineering College, Ghaziabad, Mentor: Mr. Kamal Bhatia, Submission Date: 20/11/2026.
4. **Downloads Folder (`C:\Users\arsha\Downloads\`):**
   - `Project_Brief.docx` (48,686 bytes) — HCLTech Career Shaper Programme Project 20 brief.
   - `Project_Synopsis_Template.docx` (48,516 bytes) — blank HCL template.
   - `dataset.csv` (20,420 bytes) — 501 lines (header + 500 rows), RISC-V instruction trace.
   - `data_dictionary (1).csv` (856 bytes) — 9-row skeleton dictionary with `[Learner to fill in description]`.
   - `README.md` (3,692 bytes) — matches GitHub README except Author is listed as `Anuj Bansal`.
   - `Files.zip` (2,341,533 bytes) — contains `Arshad_Ali_Project_Synopsis_With_Schematics-1.docx`.
   - **Missing from Downloads:** `Dataset_Generation_Prompt.txt` (referenced in `Project_Brief.docx` Section 6).

## 2. Backup Status
Original sources have been preserved untouched in `D:\axi\` and `C:\Users\arsha\Downloads\`, and copied into:
- `d:\hcl project axi liteburst\backup_original\axi\`
- `d:\hcl project axi liteburst\backup_original\docs_source\`
- `d:\hcl project axi liteburst\dataset\dataset.csv`
