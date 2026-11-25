# Test Plan — AXI-LiteBurst-32

**Simulator:** Icarus Verilog v12.0 (`iverilog -Wall -g2005` + `vvp`), Vivado XSIM ready (`scripts/run_simulation.tcl`)  
**Scope:** 13 unit testbenches + 1 full-system integration testbench (`tb_axi_liteburst32_top`) + 1 parameter-variation testbench (`tb_axi_liteburst32_param`).

## 27 Mandatory Test Scenarios
| Scenario | Description | Testbench | Pass Criteria |
|---|---|---|---|
| TC-01 | Synchronous reset | `tb_axi_liteburst32_top` | `s_awready/wready/arready=1`, `bvalid/rvalid=0`, memory cleared |
| TC-02 | Single write (`len=0`) | `tb_axi_liteburst32_top` | `BRESP=OKAY`, golden `ref_mem` updated |
| TC-03 | Single read (`len=0`) | `tb_axi_liteburst32_top` | `RRESP=OKAY`, `RLAST=1`, `RDATA==ref_mem` |
| TC-04 | Sequential single writes | `tb_axi_liteburst32_top` | 4 consecutive writes commit without corruption |
| TC-05 | Sequential single reads | `tb_axi_liteburst32_top` | 4 consecutive reads match `ref_mem` |
| TC-06 | Max 16-beat write burst (`len=15`) | `tb_axi_liteburst32_top` | All 16 words written, `BRESP=OKAY` |
| TC-07 | Max 16-beat read burst (`len=15`) | `tb_axi_liteburst32_top` | 16 beats returned, `RLAST` only on beat 15 |
| TC-08 | Minimum-length burst (`1` beat & `FIXED`) | `tb_axi_liteburst32_top` | `len=0` and `FIXED` `2'b00` behave cleanly |
| TC-09 | Address incrementing (`+4` stride) | `tb_axi_liteburst32_top` | Burst beats map to `addr + 4*k` |
| TC-10 | `WSTRB` byte-lane masking | `tb_axi_liteburst32_top` | Individual byte lanes `0001/0010/0100/1000` verified |
| TC-11 | Invalid address access | `tb_axi_liteburst32_top` | Unaligned `0x01`/`0x02` & unpriv Bank 1 rejected |
| TC-12 | `DECERR` generation | `tb_axi_liteburst32_top` | `0x80` and `0xFC` overflow burst return `2'b11` |
| TC-13 | `SLVERR` generation | `tb_axi_liteburst32_top` | Unaligned, `AxPROT` violation, `WRAP` burst, `WLAST` error return `2'b10` |
| TC-14 | Read/write concurrency + collision | `tb_axi_liteburst32_top` | Concurrent 8-beat W+R and same-word write-first arbitration |
| TC-15 | `AW`/`W` timing independence | `tb_axi_liteburst32_top` | AW-first, W-first, and simultaneous arrival pass |
| TC-16 | Backpressure on `B` channel | `tb_axi_liteburst32_top` | `s_bvalid`/`s_bresp` stable across 4 `BREADY=0` cycles |
| TC-17 | Backpressure on `R` channel | `tb_axi_liteburst32_top` | `s_rvalid`/`s_rdata`/`s_rresp`/`s_rlast` stable across 3 `RREADY=0` cycles |
| TC-18 | Handshake delays & `WLAST` mismatch | `tb_axi_liteburst32_top` | Early `WLAST` and missing `WLAST` return `SLVERR` without deadlock |
| TC-19 | Reset during active transaction | `tb_axi_liteburst32_top` | Mid-transaction `resetn=0` clears state cleanly |
| TC-20 | Reset during active burst | `tb_axi_liteburst32_top` | Mid-16-beat burst `resetn=0` recovers cleanly |
| TC-21 | Burst completion | `tb_axi_liteburst32_top` | `BVALID` after final `W` beat; `RLAST` on final `R` beat |
| TC-22 | Burst boundary conditions | `tb_axi_liteburst32_top` | Cross-bank `0x38` len=3 returns `SLVERR` |
| TC-23 | Memory-bank isolation | `tb_axi_liteburst32_top` | Bank 0/1 isolated; unauthorized Bank 1 read returns `32'h0` |
| TC-24 | Low-power idle entry | `tb_axi_liteburst32_top` | `low_power_idle` asserts after `IDLE_THRESHOLD` cycles |
| TC-25 | Low-power wake-up | `tb_axi_liteburst32_top` | Immediate wake-up on `s_arvalid` |
| TC-26 | Parameter variations | `tb_axi_liteburst32_param` | `ADDR_WIDTH=10, NUM_BANKS=4, BANK_WORDS=16, PROT_BANK_MASK=4'b1100` |
| TC-27 | Repeated randomized transactions | `tb_axi_liteburst32_top` | 20 randomized R/W bursts with random strobes & AW/W modes |
