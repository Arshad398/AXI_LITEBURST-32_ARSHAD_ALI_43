# Regression Report — AXI-LiteBurst-32

**Execution Date:** 2026-11-25  
**Simulator:** Icarus Verilog v12.0 (`-Wall -g2005`)  
**Log File:** `sim/regression.log`  
**Waveform:** `sim/tb_axi_liteburst32_top.vcd`

## Results Summary
| Testbench | Scope | Result | Checks / Errors |
|---|---|---|---|
| `tb_address_decoder` | Unit | **PASS** | `errors=0` |
| `tb_axi_ar_channel` | Unit | **PASS** | `errors=0` |
| `tb_axi_aw_channel` | Unit | **PASS** | `errors=0` |
| `tb_axi_b_channel` | Unit | **PASS** | `errors=0` |
| `tb_axi_r_channel` | Unit | **PASS** | `errors=0` |
| `tb_axi_slave_fsm` | Unit | **PASS** | `errors=0` |
| `tb_axi_w_channel` | Unit | **PASS** | `errors=0` |
| `tb_burst_controller` | Unit | **PASS** | `errors=0` |
| `tb_low_power_controller` | Unit | **PASS** | `errors=0` |
| `tb_read_data_path` | Unit | **PASS** | `errors=0` |
| `tb_reg_mem_bank` | Unit | **PASS** | `errors=0` |
| `tb_response_generator` | Unit | **PASS** | `errors=0` |
| `tb_write_data_path` | Unit | **PASS** | `errors=0` |
| `tb_axi_liteburst32_param` | Parameterization (`TC-26`) | **PASS** | `errors=0` |
| `tb_axi_liteburst32_top` | System (`TC-01..25, TC-27`) | **PASS** | `checks=196, errors=0` |
| **TOTAL** | **15 Testbenches** | **15 / 15 PASS** | **0 failures** |
