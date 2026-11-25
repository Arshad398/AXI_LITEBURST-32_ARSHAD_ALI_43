# Module Documentation — AXI-LiteBurst-32

1. **`axi_liteburst32_top.v`**: Top-level 122-pin wrapper integrating all 13 sub-modules, dual burst engines, dual decoders/response encoders, concurrent FSM, multi-bank register memory, and low-power controller.
2. **`axi_aw_channel.v`**: Captures `s_awaddr`, `s_awlen`, `s_awburst`, `s_awprot` on `s_awvalid && s_awready`; holds `aw_pending` until `aw_consume`.
3. **`axi_w_channel.v`**: 1-deep streaming `W` stage supporting 1-beat/cycle throughput, `s_wdata`, `s_wstrb`, `s_wlast`, and independent W-first arrival.
4. **`axi_b_channel.v`**: Registers `s_bresp` and `s_bvalid`, holding them stable across `s_bready == 0` backpressure.
5. **`axi_ar_channel.v`**: Captures `s_araddr`, `s_arlen`, `s_arburst`, `s_arprot` on `s_arvalid && s_arready`; holds `ar_pending` until `ar_consume`.
6. **`axi_r_channel.v`**: Registers `s_rdata`, `s_rresp`, `s_rlast`, and `s_rvalid`, supporting 1-beat/cycle read bursts and full `s_rready == 0` backpressure stability.
7. **`burst_controller.v`**: Parameterized 1–16 beat engine tracking `beat_index`, `beat_addr` (`FIXED` or `INCR +4`), `addr_overflow` wrap-around guard, `last`, `burst_type_err`, and `cross_bank_err`.
8. **`address_decoder.v`**: Decodes byte address into `bank_sel` and `word_index`, checking alignment (`addr[1:0]==0`), range (`in_range`), and `AxPROT[0]` privilege for protected banks (`PROT_BANK_MASK`).
9. **`response_generator.v`**: Priority encoder outputting `DECERR (2'b11)` > `SLVERR (2'b10)` > `OKAY (2'b00)`.
10. **`write_data_path.v`**: Byte-lane `WSTRB` masking and error-beat suppression (`write_allow=0` zeroes `strb_out` and `data_out`).
11. **`read_data_path.v`**: Security-masked read mux returning `32'h0000_0000` when `read_allow=0`.
12. **`reg_mem_bank.v`**: Synchronous `NUM_BANKS × BANK_WORDS × 32-bit` register array with per-byte `wr_strb` enables and synchronous `clock_enable` (`CE`).
13. **`low_power_controller.v`**: Monitors bus/FSM activity, asserts `idle` after `IDLE_THRESHOLD` idle cycles, and drives glitch-free `clock_enable = !idle || activity || !enable`.
14. **`axi_slave_fsm.v`**: Dual concurrent Write (`W_IDLE/W_BURST/W_RESP`) and Read (`R_IDLE/R_BURST/R_WAIT_LAST`) FSMs with write-first same-word collision arbitration and sticky write-burst error tracking.
