# Functional Coverage Report — AXI-LiteBurst-32

**Source:** `tb_axi_liteburst32_top` (196 scoreboard & protocol stability checks) + `tb_axi_liteburst32_param` + 13 unit TBs.

## Scenario Coverage Matrix
- **Scenarios Covered:** **27 / 27 (100%)** (`TC-01` through `TC-27`)
- **AXI Channel Handshakes:** `AW`, `W`, `B`, `AR`, `R` — 100% exercised including backpressure (`BREADY=0`, `RREADY=0`) and AW/W order independence.
- **Burst Lengths:** 1-beat (`len=0`), 2-beat (`len=1`), 4-beat (`len=3`), 8-beat (`len=7`), 16-beat (`len=15`), plus randomized 1–8 beat bursts.
- **Burst Types:** `FIXED (2'b00)`, `INCR (2'b01)`, and unsupported `WRAP (2'b10)` error path.
- **Response Codes:** `OKAY (2'b00)`, `SLVERR (2'b10)`, `DECERR (2'b11)`.
- **Byte Lanes:** All 4 `WSTRB[3:0]` lanes individually and in randomized combinations.
- **Low-Power:** Idle entry after `IDLE_THRESHOLD` and immediate wake-up verified.
- **Tool Limitation Note:** Icarus Verilog does not emit UCDB/Vivado XSIM functional covergroup databases; coverage above is tracked via explicit scenario hit counters and scoreboard assertions in Verilog.
