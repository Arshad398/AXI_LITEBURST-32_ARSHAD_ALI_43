# Known Issues & Limitations — AXI-LiteBurst-32

1. **Vivado Synthesis & Implementation Not Executed Locally (`ISS-001`):** Xilinx Vivado is not installed on the current workstation. All Vivado Tcl scripts (`scripts/*.tcl`) and XDC constraints (`constraints/axi_liteburst32_xc7z020.xdc`) are prepared for `xc7z020clg400-1` @ 100 MHz, but post-synthesis/post-implementation timing, utilization, and power reports on the Phase 2 RTL remain pending execution on a Vivado workstation.
2. **No Physical Board Pinout (`ISS-003`):** `axi_liteburst32_xc7z020.xdc` defines the 100 MHz clock and I/O delay constraints without inventing `PACKAGE_PIN` `LOC` constraints.
3. **Dataset Schema & Row Count Discrepancy (`ISS-004`):** `Project_Brief.docx` specifies an AXI transaction log and the Synopsis claims 5,000 rows, whereas the actual supplied `dataset.csv` is a 500-row synthetic RISC-V instruction trace.
4. **Ethical Declaration Signature:** Physical/wet-ink or learner signature on the final Ethical Compliance Declaration must be dated/signed by Arshad Ali prior to HCL portal submission.
