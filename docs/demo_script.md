# 1–2 Minute Demo Script — AXI-LiteBurst-32

**Duration:** ~90 seconds | **Presenter:** Arshad Ali (Roll No: 2400320310043)

1. **[0:00–0:20] Problem & Motivation:**  
   "Good morning. Standard AMBA AXI4-Lite is ideal for lightweight peripheral control registers, but it lacks native burst transfers—forcing a full address-and-response handshake for every single 32-bit word. On the other hand, full AXI4 adds out-of-order and ID complexity that increases area and power. My project, **AXI-LiteBurst-32**, bridges this gap with an AXI4-Lite-compatible slave IP featuring a controlled 1-to-16 beat custom burst extension and glitch-free low-power management."

2. **[0:20–0:50] Architecture & Key Engineering Features:**  
   "The RTL comprises 14 modular Verilog modules integrated under `axi_liteburst32_top`. It preserves all five independent AXI channels—AW, W, B, AR, and R—and adds explicit burst controls (`AxLEN`, `AxBURST`, `WLAST`, `RLAST`). A dual concurrent FSM lets reads and writes run in parallel across isolated register banks, with deterministic write-first arbitration on same-word collisions. For security, `address_decoder` and `response_generator` enforce alignment, bounds, and `AxPROT[0]` privilege protection, returning `OKAY`, `SLVERR`, or `DECERR` and zero-masking disallowed reads. For low power, `low_power_controller` drives synchronous FPGA `CE` enables with zero clock glitches."

3. **[0:50–1:25] Verification & Data Analytics Evidence:**  
   "I verified the full design using 15 self-checking Verilog testbenches in Icarus Verilog—13 unit tests, a parameter-variation test, and a 196-check system testbench covering 16-beat bursts, `WSTRB` byte masking, backpressure, reset-mid-burst, and low-power wake-up—achieving **15/15 PASS with zero errors**. I also prepared reproducible Vivado Tcl and 100 MHz XDC scripts for `xc7z020clg400-1`, and completed the Python EDA pipeline on the supplied 500-row dataset with four visualizations. Thank you."
