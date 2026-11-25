# Synthesis Report — AXI-LiteBurst-32

**Target Part:** `xc7z020clg400-1` (Zynq-7000 Artix-7 Fabric)  
**Target Clock:** 100 MHz (`10.000 ns` period in `constraints/axi_liteburst32_xc7z020.xdc`)  
**Automation Script:** `scripts/run_synthesis.tcl`

## Status: PENDING VIVADO EXECUTION
Xilinx Vivado is **not installed** on the current host workstation. Therefore, Vivado synthesis (`synth_1`) has **not** been executed on the Phase 2 RTL, and no Vivado post-synthesis utilization or timing numbers are claimed here.

## Pre-Synthesis Verification Performed Locally
- **Elaboration & Lint:** All 14 modules in `rtl/*.v` compiled and elaborated with **0 errors and 0 warnings** using Icarus Verilog (`iverilog -Wall -g2005 -s axi_liteburst32_top`).
- **Pin Budget Check:** `axi_liteburst32_top` uses **122 I/O pins** (`<= 125` available I/O pins on `xc7z020clg400-1`).
- **Synthesizable Coding Checks:** Zero inferred latches, synchronous active-low reset, glitch-free synchronous `clock_enable` (`CE`) gating on `reg_mem_bank`.

## How to Run on a Vivado Workstation
```tcl
vivado -mode batch -source scripts/create_fresh_project.tcl
vivado -mode batch -source scripts/run_synthesis.tcl
```
