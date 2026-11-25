# Register Memory Map — AXI-LiteBurst-32

**Address Width:** `ADDR_WIDTH = 8` (256-byte window `0x00 .. 0xFF`)  
**Total Mapped Memory:** `NUM_BANKS * BANK_WORDS = 2 * 16 = 32` × 32-bit words (`128` bytes: `0x00 .. 0x7F`)  
**Unmapped Space:** `0x80 .. 0xFF` (`128` bytes → returns `DECERR 2'b11`)

## 1. Bank Allocation Table
| Bank | Byte Address Range | Word Count | Access Policy | Burst Support | Error on Violation |
|---|---|---|---|---|---|
| **Bank 0** | `0x00 .. 0x3F` | 16 words (`0..15`) | Open R/W (`AxPROT[0]` = `0` or `1`) | 1–16 beats (`FIXED`/`INCR`) | Unaligned / cross-bank → `SLVERR` |
| **Bank 1** | `0x40 .. 0x7F` | 16 words (`0..15`) | **Privileged Only** (`AxPROT[0] == 1` required) | 1–16 beats (`FIXED`/`INCR`) | `AxPROT[0]==0` → `SLVERR` + zeroed read |
| **Unmapped** | `0x80 .. 0xFF` | 0 (Unmapped) | Denied | Denied | Any access → `DECERR` (`2'b11`) |

## 2. Detailed Word Offsets
### Bank 0 (`0x00 .. 0x3F`) — General Purpose Register Bank
| Offset | Register Name | Reset Value | Access | Notes |
|---|---|---|---|---|
| `0x00`..`0x3C` (4-byte stride) | `BANK0_REG[0..15]` | `0x0000_0000` | R/W (`WSTRB[3:0]`) | Supports full 16-beat write & read bursts (`0x00..0x3C`). |

### Bank 1 (`0x40 .. 0x7F`) — Protected Register Bank (`AxPROT[0] = 1` Required)
| Offset | Register Name | Reset Value | Access | Notes |
|---|---|---|---|---|
| `0x40`..`0x7C` (4-byte stride) | `BANK1_PROT_REG[0..15]` | `0x0000_0000` | Privileged R/W (`WSTRB[3:0]`) | Returns `SLVERR` if `AxPROT[0] == 0`; `RDATA = 0x0000_0000` on violation. |

## 3. Address Decoding Logic
For any byte address `addr[ADDR_WIDTH-1:0]`:
- `aligned = (addr[1:0] == 2'b00)`
- `total_bytes = NUM_BANKS * BANK_WORDS * 4` (`128` bytes for default `2×16`)
- `in_range = (addr < total_bytes)`
- `word_offset = addr[ADDR_WIDTH-1:2]`
- `bank_sel = word_offset / BANK_WORDS` (for power-of-2 `BANK_WORDS=16`: `addr[6]` selects Bank 0 vs Bank 1)
- `word_index = addr[$clog2(BANK_WORDS)+1 : 2]` (`addr[5:2]`)
- `bank_protected = PROT_BANK_MASK[bank_sel]`
- `prot_ok = !bank_protected || prot[0]`
- `addr_valid = aligned && in_range && prot_ok`
- `decode_err = !in_range` (`DECERR` has higher priority than `SLVERR`).
