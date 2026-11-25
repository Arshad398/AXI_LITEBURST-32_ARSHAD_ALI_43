# Protocol Specification — AXI-LiteBurst-32

**Document Type:** Custom AXI4-Lite Burst Extension Contract  
**Compliance Baseline:** ARM AMBA AXI4-Lite (IHI 0022E) + Custom Burst Extension

## 1. Protocol Classification Notice
Standard **AMBA AXI4-Lite does NOT support burst transactions** and does not include `AxLEN`, `AxBURST`, `WLAST`, or `RLAST`.  
**AXI-LiteBurst-32** preserves the standard 5-channel AXI4-Lite handshake architecture (`AW`, `W`, `B`, `AR`, `R`) and introduces an explicit, documented **Custom Burst Extension** for 1 to 16 beat transfers. When `s_awlen = 4'd0`, `s_awburst = 2'b01`, `s_wlast = 1'b1`, `s_arlen = 4'd0`, and `s_arburst = 2'b01`, the interface is 100% backward-compatible with single-beat AXI4-Lite transactions.

## 2. Custom Burst Extension Fields & Semantics
| Signal | Width | Direction | Encoding / Semantics |
|---|---|---|---|
| `s_awlen` | 4 | Input | Write burst beat count minus 1 (`0` = 1 beat, `15` = 16 beats). Max = 16 beats. |
| `s_awburst` | 2 | Input | Write burst type: `2'b00` = `FIXED`, `2'b01` = `INCR` (+4 bytes/beat). `2'b10`/`2'b11` = Unsupported (`SLVERR`). |
| `s_awprot` | 3 | Input | Write protection attributes (`s_awprot[0]`: `1` = Privileged, `0` = Unprivileged). |
| `s_wlast` | 1 | Input | Write last-beat indicator. Must be `1` on the final beat (`beat_index == awlen`) and `0` on earlier beats. |
| `s_arlen` | 4 | Input | Read burst beat count minus 1 (`0` = 1 beat, `15` = 16 beats). Max = 16 beats. |
| `s_arburst` | 2 | Input | Read burst type: `2'b00` = `FIXED`, `2'b01` = `INCR` (+4 bytes/beat). `2'b10`/`2'b11` = Unsupported (`SLVERR`). |
| `s_arprot` | 3 | Input | Read protection attributes (`s_arprot[0]`: `1` = Privileged, `0` = Unprivileged). |
| `s_rlast` | 1 | Output | Read last-beat indicator. Asserted `1` on the final beat (`beat_index == arlen`) of every read burst (including 1-beat reads). |

## 3. Channel Handshake & Stability Rules
1. **Rising-Edge Transfer Rule:** A beat transfers on `AW`, `W`, `B`, `AR`, or `R` if and only if `VALID && READY` is sampled high at `posedge clk`.
2. **Master/Slave Independence:**
   - Slave asserts `s_bvalid` without waiting for `s_bready`.
   - Slave asserts `s_rvalid` without waiting for `s_rready`.
   - `AW` and `W` channels accept independently: master may present `AW` before `W`, `W` before `AW`, or both simultaneously.
3. **Payload Stability Under Backpressure:**
   - Once `s_bvalid` is high and `s_bready == 0`, `s_bvalid` and `s_bresp` remain held unchanged until `s_bready == 1`.
   - Once `s_rvalid` is high and `s_rready == 0`, `s_rvalid`, `s_rdata`, `s_rresp`, and `s_rlast` remain held unchanged until `s_rready == 1`.
4. **AW/W Burst Pipelining & Boundary Rule:**
   - Once `AW` is accepted (`aw_pending == 1`), `s_awready` de-asserts until the write burst completes (`B` handshake finishes).
   - Once `AR` is accepted (`ar_pending == 1`), `s_arready` de-asserts until the final `R` beat (`s_rvalid && s_rready && s_rlast`) completes.
   - Write beat capture via `s_wready`: `s_wready` accepts beat-by-beat into the 1-deep `W` holding stage; when `AW` is present and the write beat is consumed into `reg_mem_bank`, `s_wready` re-asserts for the next beat until `awlen + 1` beats are completed.

## 4. Address Incrementing & Burst Boundary Rules
- **Burst Start Address:** Captured from `s_awaddr` / `s_araddr` on address handshake.
- **Address Incrementing:**
  - `INCR (2'b01)`: `beat_addr[k+1] = beat_addr[k] + 4` (32-bit word stride).
  - `FIXED (2'b00)`: `beat_addr[k+1] = beat_addr[k]` (repeated access to same 32-bit register).
- **Beat Counter:** `beat_index` increments `0 .. len_q` (`0 .. 15`), where `len_q` = `s_awlen` / `s_arlen`.
- **Last-Beat Detection:** `last = (beat_index == len_q)`.
- **Bank Boundary Protection:** If an `INCR` burst starts in one bank (`start_addr[BANK_MSB:BANK_LSB]`) and increments into another bank (`beat_addr` crosses bank boundary), that beat is rejected with `SLVERR` (`2'b10`) (or `DECERR` if it crosses beyond the mapped address space).

## 5. Error Response Semantics & Priority
| Priority | Condition | Response Code | Side Effect |
|---|---|---|---|
| 1 (Highest) | Address out of mapped slave memory range (`addr >= TOTAL_BYTES`) | `DECERR` (`2'b11`) | Write suppressed; Read returns `32'h0000_0000`. |
| 2 | Unaligned address (`addr[1:0] != 2'b00`) | `SLVERR` (`2'b10`) | Write suppressed; Read returns `32'h0000_0000`. |
| 3 | Protection violation (Protected Bank access with `AxPROT[0] == 0`) | `SLVERR` (`2'b10`) | Write suppressed; Read returns `32'h0000_0000`. |
| 4 | Unsupported burst type (`AxBURST == 2'b10` or `2'b11`) | `SLVERR` (`2'b10`) | Write suppressed; Read returns `32'h0000_0000`. |
| 5 | Burst crosses bank boundary (`beat_bank != start_bank`) | `SLVERR` (`2'b10`) | Out-of-bank beat suppressed; Read returns `32'h0000_0000`. |
| 6 | Write `WLAST` mismatch (early `s_wlast=1` before `awlen`, or `s_wlast=0` on final beat) | `SLVERR` (`2'b10`) | Sticky error latched for `BRESP`; extra/missing beats cleanly reconciled. |
| Default | Valid aligned permitted beat | `OKAY` (`2'b00`) | Write commits `WSTRB` lanes; Read returns register word. |

**Write Burst Error Accumulation:** Since AXI returns a single `BRESP` per write burst, errors are sticky with priority `DECERR > SLVERR > OKAY` across all beats of the write burst.  
**Read Burst Error Reporting:** AXI returns `RRESP` per beat, so each read beat accurately carries its own `OKAY` / `SLVERR` / `DECERR` status.

## 6. Reset Behavior During Active Burst
- `resetn` is synchronous, active-low (`!resetn` at `posedge clk`).
- If `resetn == 0` occurs mid-burst:
  - Write and Read FSMs immediately return to `IDLE`.
  - Both `burst_controller` instances clear `active`, `beat_index`, `beat_addr`, and `last`.
  - `s_bvalid`, `s_rvalid`, `s_rlast`, `s_awready`, `s_wready`, `s_arready` all reset to `0`.
  - `reg_mem_bank` resets all register words to `32'h0000_0000`.
