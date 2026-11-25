# Module Hierarchy — AXI-LiteBurst-32

## 1. Reconciliation of Synopsis Counts vs. Final Implementation
- The HCL Synopsis Technology Stack table stated **"11 RTL Modules, 12 Testbenches"**, whereas its Sub-Module Hierarchy bullet list and `D:\axi\design\` listed **14 RTL files** (`write_data_path.v` and `read_data_path.v` were combined on one bullet, and `burst_controller`, `axi_slave_fsm`, `reg_mem_bank` were standalone in the original baseline).
- In the production Phase 2 implementation, **all 14 RTL modules** are actively instantiated and connected in `axi_liteburst32_top.v` (with `burst_controller` instantiated twice: once for the Write Burst Engine and once for the Read Burst Engine; `address_decoder` and `response_generator` instantiated twice for independent Write and Read decode/response).

## 2. Instantiation Tree
```text
axi_liteburst32_top
├── u_aw_ch      : axi_aw_channel       (AW capture: addr, len, burst, prot)
├── u_w_ch       : axi_w_channel        (W capture/stream: data, strb, last)
├── u_b_ch       : axi_b_channel        (B response driver & BREADY hold)
├── u_ar_ch      : axi_ar_channel       (AR capture: addr, len, burst, prot)
├── u_r_ch       : axi_r_channel        (R response driver, RLAST & RREADY hold)
├── u_fsm        : axi_slave_fsm        (Dual concurrent Write/Read FSM + collision arbiter)
├── u_wr_burst   : burst_controller     (Write burst beat counter & +4 addr generator)
├── u_rd_burst   : burst_controller     (Read burst beat counter & +4 addr generator)
├── u_wr_dec     : address_decoder      (Write bank/word decode + alignment/bounds/prot check)
├── u_rd_dec     : address_decoder      (Read bank/word decode + alignment/bounds/prot check)
├── u_wr_resp    : response_generator   (Write OKAY/SLVERR/DECERR encoder)
├── u_rd_resp    : response_generator   (Read OKAY/SLVERR/DECERR encoder)
├── u_wpath      : write_data_path      (WSTRB gating & error write suppression)
├── u_rpath      : read_data_path       (Read data routing & error read zero-masking)
├── u_mem_bank   : reg_mem_bank         (Multi-bank 32-bit sync register file with CE)
└── u_lp_ctrl    : low_power_controller (Activity monitor, idle counter & clock_enable)
```

## 3. Dependency Order for Compilation & Implementation
1. Leaf modules (no sub-instantiations):
   `address_decoder`, `reg_mem_bank`, `response_generator`, `write_data_path`, `read_data_path`, `axi_aw_channel`, `axi_w_channel`, `axi_b_channel`, `axi_ar_channel`, `axi_r_channel`, `burst_controller`, `low_power_controller`, `axi_slave_fsm`.
2. Integration top:
   `axi_liteburst32_top` (depends on all 13 leaf modules).
