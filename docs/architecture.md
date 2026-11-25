# System Architecture — AXI-LiteBurst-32

**Project:** Project 20 — AXI-LiteBurst-32: Configurable AXI4-Lite Slave Interface with Burst Extension  
**Target FPGA:** Xilinx Zynq-7000 `xc7z020clg400-1` @ 100 MHz (10.0 ns period)  
**Design Width:** 32-bit Data Bus, Configurable Address Width (default 8-bit)  
**Maximum Burst Length:** 16 beats

## 1. Architectural Overview
AXI-LiteBurst-32 is a modular 5-channel AXI4-Lite-compatible slave IP extended with a controlled custom burst engine supporting 1 to 16 beat transactions, multi-bank memory isolation, byte-lane write masking (`WSTRB[3:0]`), address decode & privilege protection, deterministic error reporting (`OKAY`, `SLVERR`, `DECERR`), and glitch-free synchronous low-power clock-enable management.

Unlike the disconnected Phase 0 baseline where `burst_controller`, `axi_slave_fsm`, and `reg_mem_bank` were uninstantiated, the production Phase 1/2 architecture integrates all 14 modules into a unified, concurrent dual-engine slave architecture:

1. **Independent Write Path Engine:**
   - `axi_aw_channel`: Accepts and buffers write address, burst length (`s_awlen`), burst type (`s_awburst`), and protection (`s_awprot`).
   - `axi_w_channel`: Accepts and buffers write data (`s_wdata`), byte strobes (`s_wstrb`), and `s_wlast` per beat. Supports AW-first, W-first, and simultaneous AW/W arrival.
   - `burst_controller` (`u_wr_burst`): Tracks write beat index (`0..15`), calculates beat addresses (`FIXED` or `INCR +4`), detects final beat (`last`), and validates bank/region boundaries.
   - `write_data_path`: Formats and aligns `WDATA`/`WSTRB` per beat, gating off writes when an error (`SLVERR`/`DECERR`) is detected.
   - `axi_b_channel`: Latches worst-case burst write response (`OKAY`/`SLVERR`/`DECERR`) at burst completion and holds `s_bvalid`/`s_bresp` stable until `s_bready`.

2. **Independent Read Path Engine:**
   - `axi_ar_channel`: Accepts and buffers read address, burst length (`s_arlen`), burst type (`s_arburst`), and protection (`s_arprot`).
   - `burst_controller` (`u_rd_burst`): Tracks read beat index (`0..15`), calculates beat addresses (`FIXED` or `INCR +4`), and drives `last` for `s_rlast`.
   - `read_data_path`: Routes `reg_mem_bank` read data when access is valid, or zeroes `RDATA` (`32'h0000_0000`) on `SLVERR`/`DECERR` to prevent unauthorized data leakage.
   - `axi_r_channel`: Registers `s_rdata`, `s_rresp`, `s_rlast`, and `s_rvalid` per beat, holding them completely stable during `s_rready == 0` backpressure.

3. **Central Coordination, Protection & Memory Subsystem:**
   - `axi_slave_fsm`: Dual concurrent FSM (independent Write FSM and Read FSM) with deterministic **write-first same-word collision arbitration** for `reg_mem_bank`. Reads and writes to different addresses execute in parallel in the same clock cycle with zero serialization penalty.
   - `address_decoder` (`u_wr_dec`, `u_rd_dec`): Decodes byte addresses into bank select + word index, checks 32-bit alignment, mapped bounds, and `AxPROT[0]` privilege protection for protected banks.
   - `response_generator` (`u_wr_resp_gen`, `u_rd_resp_gen`): Deterministically maps decode/alignment/protection/protocol flags to `OKAY (2'b00)`, `SLVERR (2'b10)`, or `DECERR (2'b11)`.
   - `reg_mem_bank`: Configurable multi-bank 32-bit synchronous register array (`NUM_BANKS × BANK_WORDS × 32-bit`, default `2 × 16 = 32` words = 128 bytes) with per-byte `WSTRB` write enables and synchronous `clock_enable` (`CE`) support.
   - `low_power_controller`: Monitors all 5 AXI channel activities and active burst states, asserting `low_power_idle` after `IDLE_THRESHOLD` idle cycles and driving glitch-free synchronous `clock_enable` to inactive datapath/bank registers (never gating the clock net directly).

## 2. Concurrency & Arbitration Strategy
- **Dual-Port Register Memory Model:** `reg_mem_bank` exposes one synchronous write port (`wr_en`, `wr_bank`, `wr_index`, `wr_data`, `wr_strb`) and one combinational/registered read port (`rd_en`, `rd_bank`, `rd_index`, `rd_data`).
- **True Read/Write Parallelism:** Whenever `(wr_bank != rd_bank) || (wr_index != rd_index)`, writes and reads proceed concurrently in the same clock cycle.
- **Same-Word Collision Policy (Write-First Priority):** If an active write beat and an active read beat target the identical `(bank, word_index)` in the same clock cycle, `axi_slave_fsm` grants `wr_mem_en` immediately and holds `rd_mem_en` for 1 cycle so the read deterministically observes the newly written value.
- **No Global Cross-Channel Blocking:** `B` backpressure (`s_bready=0`) does not stall `AR`/`R`, and `R` backpressure (`s_rready=0`) does not stall `AW`/`W`/`B`.

## 3. Low-Power Clock-Enable Architecture
- **Safe FPGA Technique:** Xilinx 7-series FFs (`FDRE`/`FDCE`) provide dedicated synchronous Clock Enable (`CE`) inputs. Using `clock_enable` on register enables rather than gated clock trees (`clk & en`) avoids clock skew, setup/hold glitches, and DRC warnings.
- **Wake-Up Latency:** `clock_enable = !idle || activity` is combinational on `activity`, ensuring **0-cycle wake-up** whenever any `VALID` or internal pending/burst signal asserts.
- **Register Retention:** When `low_power_idle == 1`, memory contents and holding registers retain state undisturbed while internal sequential logic (`reg_mem_bank` write/read FFs, idle-gated shadow pipelines) suppresses switching activity.
