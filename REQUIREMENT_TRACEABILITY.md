# REQUIREMENT_TRACEABILITY.md

| Req ID | Requirement | Target RTL Module(s) | Planned Test Case(s) | Phase 0 Evidence / Status |
|---|---|---|---|---|
| REQ-01 | 5-channel AXI4-Lite slave (AW, W, B, AR, R) | `axi_aw_channel`, `axi_w_channel`, `axi_b_channel`, `axi_ar_channel`, `axi_r_channel`, `axi_liteburst32_top` | TC-01..TC-17 | Audited in `D:\axi\design\`; single-beat present, needs burst integration |
| REQ-02 | Configurable 32-bit data, parameterized addr/depth | `axi_liteburst32_top`, `reg_mem_bank`, `address_decoder` | TC-26 | Audited; `ADDR_WIDTH=8`, `DATA_WIDTH=32`, `MEM_WORDS=16` |
| REQ-03 | Custom burst extension (1–16 beats, +4 addr) | `burst_controller`, `axi_slave_fsm`, `axi_liteburst32_top` | TC-06..TC-09, TC-20..TC-22 | **GAP:** `burst_controller.v` disconnected from top-level |
| REQ-04 | Independent read & write concurrency | `axi_liteburst32_top`, `axi_slave_fsm`, `reg_mem_bank` | TC-14, TC-15 | Audited; read/write arbitration to be specified in Phase 1 |
| REQ-05 | Byte-lane write masking (`WSTRB[3:0]`) | `write_data_path`, `reg_mem_bank` | TC-10 | Audited; single-beat works, needs burst verification |
| REQ-06 | Protected address decoding & bank isolation | `address_decoder`, `reg_mem_bank` | TC-11, TC-23 | Audited; bounds/alignment check present, protection to be expanded |
| REQ-07 | Deterministic responses (`OKAY`, `SLVERR`, `DECERR`) | `response_generator` | TC-12, TC-13 | **GAP:** `DECERR` (`2'b11`) not yet implemented |
| REQ-08 | Low-power activity detection & clock-enable | `low_power_controller`, `axi_liteburst32_top` | TC-24, TC-25 | **GAP:** `clock_enable` currently unused in top-level |
| REQ-09 | Vivado synthesis, implementation & timing closure | `scripts/*.tcl`, `constraints/*.xdc` | Vivado flow | **BLOCKED:** Vivado not installed; no XDC/part confirmed |
| REQ-10 | Dataset cleaning, dictionary & 3+ visualizations | `dataset/`, `analysis/` | EDA scripts | **DISCREPANCY/BLOCKED:** 500-row RISC-V trace supplied; Python not installed |
