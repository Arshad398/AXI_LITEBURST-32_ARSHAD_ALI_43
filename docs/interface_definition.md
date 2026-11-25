# Interface Definition — `axi_liteburst32_top`

**Target Device:** `xc7z020clg400-1` (125 available package I/O pins)  
**Top-Level Pin Count:** **122 I/O pins** (fits within 125 I/O limit with 3 pins margin)

## 1. Parameters
| Parameter | Default | Description |
|---|---|---|
| `ADDR_WIDTH` | `8` | Byte address width (`8` → 256-byte address window). |
| `DATA_WIDTH` | `32` | Data bus width (fixed 32-bit design width). |
| `NUM_BANKS` | `2` | Number of independent register banks (`2` banks). |
| `BANK_WORDS` | `16` | 32-bit words per bank (`16` words = 64 bytes/bank, supporting max 16-beat burst). |
| `PROT_BANK_MASK` | `2'b10` | Bitmask of banks requiring privileged access (`AxPROT[0] == 1`). Default protects Bank 1 (`0x40..0x7F`). |
| `IDLE_THRESHOLD` | `8` | Idle clock cycles before `low_power_idle` asserts (`8` cycles default). |

## 2. Top-Level Port List (`axi_liteburst32_top`)
| Port | Dir | Width | Domain / Channel | Description |
|---|---|---|---|---|
| `clk` | In | 1 | Global | System clock (100 MHz target). |
| `resetn` | In | 1 | Global | Synchronous active-low reset. |
| `s_awaddr` | In | `ADDR_WIDTH` | AW (Std) | Write burst start byte address. |
| `s_awlen` | In | 4 | AW (Burst Ext) | Write burst length minus 1 (`0..15` → `1..16` beats). |
| `s_awburst` | In | 2 | AW (Burst Ext) | Write burst type (`2'b00` FIXED, `2'b01` INCR). |
| `s_awprot` | In | 3 | AW (Std) | Write protection (`s_awprot[0]` = privileged). |
| `s_awvalid` | In | 1 | AW (Std) | Write address valid. |
| `s_awready` | Out | 1 | AW (Std) | Write address ready. |
| `s_wdata` | In | `DATA_WIDTH` | W (Std) | Write data beat (32-bit). |
| `s_wstrb` | In | `DATA_WIDTH/8` | W (Std) | Write byte-lane strobes (`[3:0]`). |
| `s_wlast` | In | 1 | W (Burst Ext) | Write last beat indicator. |
| `s_wvalid` | In | 1 | W (Std) | Write data valid. |
| `s_wready` | Out | 1 | W (Std) | Write data ready. |
| `s_bresp` | Out | 2 | B (Std) | Write response (`00` OKAY, `10` SLVERR, `11` DECERR). |
| `s_bvalid` | Out | 1 | B (Std) | Write response valid. |
| `s_bready` | In | 1 | B (Std) | Write response ready. |
| `s_araddr` | In | `ADDR_WIDTH` | AR (Std) | Read burst start byte address. |
| `s_arlen` | In | 4 | AR (Burst Ext) | Read burst length minus 1 (`0..15` → `1..16` beats). |
| `s_arburst` | In | 2 | AR (Burst Ext) | Read burst type (`2'b00` FIXED, `2'b01` INCR). |
| `s_arprot` | In | 3 | AR (Std) | Read protection (`s_arprot[0]` = privileged). |
| `s_arvalid` | In | 1 | AR (Std) | Read address valid. |
| `s_arready` | Out | 1 | AR (Std) | Read address ready. |
| `s_rdata` | Out | `DATA_WIDTH` | R (Std) | Read data beat (32-bit). |
| `s_rresp` | Out | 2 | R (Std) | Read response (`00` OKAY, `10` SLVERR, `11` DECERR). |
| `s_rlast` | Out | 1 | R (Burst Ext) | Read last beat indicator. |
| `s_rvalid` | Out | 1 | R (Std) | Read data valid. |
| `s_rready` | In | 1 | R (Std) | Read data ready. |
| `low_power_enable` | In | 1 | Power Mgmt | Enables idle detection and synchronous clock-enable gating. |
| `low_power_idle` | Out | 1 | Power Mgmt | High when bus has been idle for `IDLE_THRESHOLD` cycles. |

**Pin Count Verification (Default `ADDR_WIDTH=8, DATA_WIDTH=32`):**  
`2 (clk/resetn) + 19 (AW) + 39 (W) + 4 (B) + 19 (AR) + 37 (R) + 2 (LP) = 122 pins <= 125 IOs`.
