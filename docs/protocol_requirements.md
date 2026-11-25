# Protocol Requirements — AXI-LiteBurst-32

**Date:** 2026-11-25  
**Scope:** Baseline protocol audit in Phase 0 (full specification to be finalized in Phase 1).

## 1. Standard AXI4-Lite Compliance Boundary
Per ARM AMBA AXI and ACE Protocol Specification (IHI 0022E):
- **Standard AXI4-Lite DOES NOT support burst transactions.** Every AW/W transaction is strictly a single 1-beat data transfer, and every AR transaction returns a single 1-beat R transfer. Standard AXI4-Lite omits `AxLEN`, `AxSIZE`, `AxBURST`, `WLAST`, and `RLAST`.
- Therefore, **AXI-LiteBurst-32 MUST be specified and documented as an AXI4-Lite-compatible slave with a custom burst extension**—never misrepresented as native AXI4-Lite behavior.

## 2. Five-Channel Architecture (Preserved)
1. **AW (Write Address):** `s_awvalid`, `s_awready`, `s_awaddr` (+ custom burst extension fields if bus-driven, e.g., `s_awlen` / `s_awburst` or control register).
2. **W (Write Data):** `s_wvalid`, `s_wready`, `s_wdata[31:0]`, `s_wstrb[3:0]` (+ `s_wlast` if multi-beat streaming W channel is used).
3. **B (Write Response):** `s_bvalid`, `s_bready`, `s_bresp[1:0]`.
4. **AR (Read Address):** `s_arvalid`, `s_arready`, `s_araddr` (+ custom burst extension fields).
5. **R (Read Data):** `s_rdata[31:0]`, `s_rresp[1:0]`, `s_rvalid`, `s_rready` (+ `s_rlast` for read burst termination).

## 3. Handshake & Stability Rules Required
- Transfer occurs **only** when `VALID && READY` on the rising clock edge (`clk`).
- Once `VALID` is asserted, it **must remain high** and its payload (`AWADDR`, `WDATA`, `WSTRB`, `BRESP`, `RDATA`, `RRESP`) **must remain stable** until `READY` is sampled high.
- Slave must **not** wait for `BREADY` before asserting `BVALID`, nor wait for `RREADY` before asserting `RVALID`.
- `AW` and `W` arrival order must remain independent (AW-first, W-first, or simultaneous).
- Read (`AR`/`R`) and Write (`AW`/`W`/`B`) channels must operate concurrently without unnecessarily serializing both behind a single blocking FSM.

## 4. Custom Burst Extension & Protection Requirements (From Brief, Synopsis & Prompt)
- **Maximum Burst Length:** 16 beats (minimum 1 beat — backward-compatible with standard single-beat AXI4-Lite when burst length = 1 / 0-encoded).
- **Addressing:** 32-bit word-aligned (`addr[1:0] == 2'b00`), 4-byte (`+4`) sequential address increment per beat.
- **Byte Masking:** `WSTRB[3:0]` applied per byte lane on every write beat.
- **Response Codes:**
  - `2'b00` (`OKAY`): Valid aligned in-range transfer/burst.
  - `2'b10` (`SLVERR`): Slave error (e.g., unaligned address, invalid burst length `0` or `>16`, burst crossing memory boundary, or write to read-only/protected register).
  - `2'b11` (`DECERR`): Decode error (address completely outside slave memory map range, or unauthorized master/protection violation).
- **Reset Behavior:** Synchronous active-low `resetn` must cleanly abort any active single or burst transaction, de-assert `BVALID`/`RVALID`, clear pending flags, and reset register banks deterministically.

## 5. Current RTL vs. Protocol Gap Summary
In `D:\axi\design\axi_liteburst32_top.v`:
- `axi_liteburst32_top` currently has **zero burst ports** and **does not instantiate `burst_controller.v`** (so multi-beat bursts are not supported at the IP boundary).
- `response_generator.v` only generates `OKAY` (`2'b00`) and `SLVERR` (`2'b10`); `DECERR` (`2'b11`) is unimplemented.
- `axi_slave_fsm.v` in `D:\axi\design\` is only a 2-line pulse helper, not the 6-state FSM described in the synopsis.
