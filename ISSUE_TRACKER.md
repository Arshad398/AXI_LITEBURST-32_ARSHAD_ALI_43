# ISSUE_TRACKER.md

| ID | Severity | Category | Description | Status |
|---|---|---|---|---|
| ISS-001 | CRITICAL | Environment | Xilinx Vivado / XSIM (and any HDL simulator) is not installed on this PC. | OPEN — Blocked on user/environment |
| ISS-002 | HIGH | Environment | Python is not installed on this PC (only Windows Store stub present). | OPEN — Blocked on user/environment |
| ISS-003 | HIGH | Target / Constraints | No `.xpr`, `.tcl`, or `.xdc` supplied; FPGA part unspecified in text (`xc7z020clg400-1` inferred from screenshots); timing unconstrained (`WNS=inf`). | OPEN — Needs user confirmation |
| ISS-004 | HIGH | Dataset | `dataset.csv` is a 500-row RISC-V trace, contradicting `Project_Brief.docx` (AXI transaction log) and Synopsis (claims 5,000 rows). `Dataset_Generation_Prompt.txt` missing. | OPEN — Needs user confirmation |
| ISS-005 | CRITICAL | RTL Architecture | `axi_liteburst32_top.v` does not instantiate `burst_controller.v`, `axi_slave_fsm.v`, or `reg_mem_bank.v`, and has no burst interface ports. | OPEN — To fix in Phase 1/2 |
| ISS-006 | HIGH | RTL Protocol | `response_generator.v` only drives `OKAY` (`2'b00`) and `SLVERR` (`2'b10`); `DECERR` (`2'b11`) is not implemented. | OPEN — To fix in Phase 1/2 |
| ISS-007 | MEDIUM | RTL Low-Power | `low_power_controller.v` `clock_enable` output is tied to `unused_clock_enable` in `axi_liteburst32_top.v`. | OPEN — To fix in Phase 1/2 |
| ISS-008 | HIGH | Verification | 5 unit TBs (`tb_axi_ar_channel`, `tb_axi_b_channel`, `tb_axi_r_channel`, `tb_axi_slave_fsm`, `tb_axi_w_channel`) fail to wire `.resetn(resetn)`. | OPEN — To fix in Phase 3 |
| ISS-009 | MEDIUM | Verification | `tb_axi_aw_channel.v` is missing from `D:\axi\testbench\` and GitHub (only 13 TBs present vs 14 stated in README and 12 in Synopsis). | OPEN — To fix in Phase 3 |
| ISS-010 | LOW | Documentation | Module/TB count discrepancies across Synopsis (`11 RTL, 12 TBs`), Hierarchy (`14`), `README.md` (`14 TBs`), and `Downloads\README.md` author (`Anuj Bansal` vs `Arshad Ali`). | OPEN — To reconcile |
