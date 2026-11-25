# Environment Report — Phase 0

**Host OS:** Microsoft Windows  
**Workspace:** `d:\hcl project axi liteburst`  
**Audit Date:** 2026-11-25

## 1. Logical Drives & Storage
- `C:\` — Fixed NTFS, ~142.35 GB total, ~51.96 GB free
- `D:\` — Fixed NTFS, ~367.00 GB total, ~359.68 GB free

## 2. EDA & Simulation Toolchain Discovery
Full recursive scans of `C:\` and `D:\`, `PATH`, Windows Registry uninstall keys (`HKLM`/`HKCU`), Start Menu, and WSL were executed:

| Tool / Component | Status | Evidence / Findings |
|---|---|---|
| Xilinx / AMD Vivado | **NOT INSTALLED** | No `vivado.bat`, `C:\Xilinx`, `C:\AMD`, `D:\Xilinx`, registry entries, or `XILINX_VIVADO` env var found. (Synopsis cites Vivado 2025.2 from external/earlier environment.) |
| Vivado XSIM (`xvlog`/`xelab`/`xsim`) | **NOT INSTALLED** | Absent along with Vivado. |
| ModelSim / QuestaSim | **NOT INSTALLED** | No `vsim` binary or registry entry found. |
| Icarus Verilog / Verilator | **NOT INSTALLED** | No `iverilog`, `vvp`, or `verilator` binary found across `C:\` and `D:\`. |
| Python (`python` / `py` / `conda`) | **NOT INSTALLED** | `where.exe python` only resolves to Windows Store stub `C:\Users\arsha\AppData\Local\Microsoft\WindowsApps\python.exe`, which fails execution (`The file cannot be accessed by the system`). |
| Git | **NOT INSTALLED** | `where.exe git` returned not found. |
| WSL (Windows Subsystem for Linux) | **NOT INSTALLED** | `wsl --status` reports WSL is not installed. |
| PowerShell | **AVAILABLE** | Windows PowerShell 5.1 (`C:\Windows\System32\WindowsPowerShell\v1.0\`). |
| `winget` | **AVAILABLE** | `C:\Users\arsha\AppData\Local\Microsoft\WindowsApps\winget.exe`. |

## 3. Target FPGA Part Identification
- **Authoritative `.xpr` / `.tcl` / `.xdc` files:** None found locally or in `Arshad398/AXI_LITEBURST-32_ARSHAD_ALI`.
- **Synopsis Text:** Lists multiple families generically (`Xilinx Artix-7 / Kintex-7 / UltraScale+ FPGA / Generic ASIC Synthesis`).
- **Vivado Screenshots Evidence (`D:\axi\Reports\` and `D:\axi\device\`):**
  - Utilization screenshot reports total resources: **LUT = 53,200**, **FF = 106,400**, **IO = 125**, **BUFG = 32**.
  - Device floorplan screenshot shows a Zynq-7000 die with 6 clock-region grid (`X0Y0..X1Y2`) where `X0Y1`/`X0Y2` have the Processing System (PS7) cutout on the left.
  - These exact capacities and die layout correspond to **Xilinx Zynq-7000 `xc7z020clg400-1`** (Artix-7 28nm programmable logic fabric).
- **Constraint Status:** Timing Summary screenshot explicitly states *"There are no user specified timing constraints"* (`WNS = inf`, `WHS = inf`). No `.xdc` clock or pin constraints exist.

## 4. Critical Environment Blockers
1. **No RTL Simulator or Vivado Installed:** Phases 3, 4, 5, and 6 cannot execute real Vivado behavioral simulation, synthesis, placement, routing, or timing/power analysis on this machine until Vivado (or an approved simulator for Phase 3) is installed.
2. **No Python Environment Installed:** Phase 7 EDA scripts/notebooks (`pandas`, `matplotlib`, `jupyter`) require Python installation (e.g., via `winget` or user installation) or user confirmation of an alternate workflow.
3. **Target Part & Clock Frequency Confirmation Needed:** Must confirm `xc7z020clg400-1` (or another Artix-7/Kintex-7/UltraScale+ part) and target clock frequency (e.g., 100 MHz / 10 ns) before physical implementation.
