# Parameter Configuration Guide — AXI-LiteBurst-32

## 1. Top-Level Parameters (`axi_liteburst32_top`)
| Parameter | Default | Allowed Range / Constraints | Effect |
|---|---|---|---|
| `ADDR_WIDTH` | `8` | `6 .. 32` (must cover `NUM_BANKS * BANK_WORDS * 4`) | Byte address bus width. Default `8` covers 256 bytes (`0x00..0xFF`). |
| `DATA_WIDTH` | `32` | `32` (fixed design width; `WSTRB = DATA_WIDTH/8`) | Data bus width in bits (`32`). |
| `NUM_BANKS` | `2` | `1 .. 8` (power-of-2 recommended) | Number of isolated register memory banks. |
| `BANK_WORDS` | `16` | `>= 16` recommended for full 16-beat bursts | 32-bit words per bank (`16` = 64 bytes per bank). |
| `PROT_BANK_MASK` | `2'b10` | `[NUM_BANKS-1:0]` bitmask | Bit `k=1` marks Bank `k` as privileged-only (`AxPROT[0]==1` required). Default protects Bank 1 (`0x40..0x7F`). |
| `IDLE_THRESHOLD` | `8` | `0 .. 255` | Consecutive idle clock cycles before `low_power_idle` asserts. |

## 2. Derived Localparams & Address Partitioning
With defaults (`ADDR_WIDTH=8`, `NUM_BANKS=2`, `BANK_WORDS=16`):
- `TOTAL_WORDS = 32` (`128` mapped bytes: `0x00 .. 0x7F`)
- `Bank 0`: `0x00 .. 0x3F` (16 words, open access)
- `Bank 1`: `0x40 .. 0x7F` (16 words, privileged access)
- `Unmapped`: `0x80 .. 0xFF` (`128` bytes, returns `DECERR 2'b11`)
- `BANK_W = 1`, `WORD_W = 4`

## 3. Alternate Verified Configuration Example
For expanded memory tests (e.g. `ADDR_WIDTH = 10`, `NUM_BANKS = 4`, `BANK_WORDS = 16`, `PROT_BANK_MASK = 4'b1100`):
- `TOTAL_WORDS = 64` (`256` mapped bytes `0x000 .. 0x0FF`)
- Banks 0 & 1 (`0x000..0x07F`): open; Banks 2 & 3 (`0x080..0x0FF`): privileged-only; `0x100..0x3FF`: `DECERR`.
