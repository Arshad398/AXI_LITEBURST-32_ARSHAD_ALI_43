"""
Builds a comprehensive, multi-page HCLTech Project Synopsis (.docx) for Arshad Ali
at docs/Project_Synopsis_Arshad_Ali_2400320310043.docx with formatted tables,
verified metrics, EDA visualizations, and baseline schematics/waveforms.
Uses only Python standard library (zipfile, html, os, struct).
"""
import os
import zipfile
import html
import struct

BASE = r"d:\hcl project axi liteburst"
OUT_DOCX = os.path.join(BASE, "docs", "Project_Synopsis_Arshad_Ali_2400320310043.docx")

def get_img_size_emu(path, max_width_in=6.3):
    with open(path, "rb") as f:
        data = f.read(32)
        if data[:8] == b"\x89PNG\r\n\x1a\n":
            w, h = struct.unpack(">II", data[16:24])
        else:
            f.seek(0)
            b = f.read()
            w, h = 1280, 720
            i = 2
            while i < len(b) - 9:
                if b[i] == 0xFF and b[i+1] in (0xC0, 0xC1, 0xC2):
                    h, w = struct.unpack(">HH", b[i+5:i+9])
                    break
                if b[i] == 0xFF and b[i+1] != 0xFF:
                    seg_len = struct.unpack(">H", b[i+2:i+4])[0]
                    i += 2 + seg_len
                else:
                    i += 1
    cx = int(max_width_in * 914400)
    cy = int(cx * (h / max(w, 1)))
    max_h = int(7.5 * 914400)
    if cy > max_h:
        cy = max_h
        cx = int(cy * (w / max(h, 1)))
    return cx, cy

media_files = []
rel_entries = []
body_parts = []
rid_counter = 1

def add_p(text, style="Normal", space_after=80, space_before=0, bold=False, color=None, size_pt=10.5, align=None):
    sz = int(size_pt * 2)
    b_xml = "<w:b/>" if bold else ""
    c_xml = f'<w:color w:val="{color}"/>' if color else ""
    jc_xml = f'<w:jc w:val="{align}"/>' if align else ""
    esc = html.escape(text)
    body_parts.append(
        f'<w:p><w:pPr>{jc_xml}<w:spacing w:before="{space_before}" w:after="{space_after}"/></w:pPr>'
        f'<w:r><w:rPr>{b_xml}{c_xml}<w:sz w:val="{sz}"/><w:szCs w:val="{sz}"/></w:rPr>'
        f'<w:t xml:space="preserve">{esc}</w:t></w:r></w:p>'
    )

def add_h1(text):
    add_p(text, space_before=220, space_after=100, bold=True, color="1F4E79", size_pt=14)

def add_h2(text):
    add_p(text, space_before=160, space_after=70, bold=True, color="2E75B6", size_pt=11.5)

def add_bullet(lead, text):
    esc_l = html.escape(lead)
    esc_t = html.escape(text)
    body_parts.append(
        f'<w:p><w:pPr><w:ind w:left="360"/><w:spacing w:after="60"/></w:pPr>'
        f'<w:r><w:rPr><w:b/><w:sz w:val="20"/></w:rPr><w:t xml:space="preserve">• {esc_l}</w:t></w:r>'
        f'<w:r><w:rPr><w:sz w:val="20"/></w:rPr><w:t xml:space="preserve">{esc_t}</w:t></w:r></w:p>'
    )

def add_page_break():
    body_parts.append('<w:p><w:r><w:br w:type="page"/></w:r></w:p>')

def add_table(headers, rows, col_widths=None):
    ncols = len(headers)
    if not col_widths:
        col_widths = [int(9360 / ncols)] * ncols
    tbl = ['<w:tbl><w:tblPr><w:tblW w:w="9360" w:type="dxa"/>'
           '<w:tblBorders>'
           '<w:top w:val="single" w:sz="6" w:color="BFBFBF"/>'
           '<w:bottom w:val="single" w:sz="6" w:color="BFBFBF"/>'
           '<w:left w:val="single" w:sz="6" w:color="BFBFBF"/>'
           '<w:right w:val="single" w:sz="6" w:color="BFBFBF"/>'
           '<w:insideH w:val="single" w:sz="4" w:color="D9D9D9"/>'
           '<w:insideV w:val="single" w:sz="4" w:color="D9D9D9"/>'
           '</w:tblBorders></w:tblPr>']
    # Header row
    tbl.append("<w:tr>")
    for i, h in enumerate(headers):
        tbl.append(
            f'<w:tc><w:tcPr><w:tcW w:w="{col_widths[i]}" w:type="dxa"/>'
            f'<w:shd w:val="clear" w:fill="1F4E79"/></w:tcPr>'
            f'<w:p><w:pPr><w:spacing w:before="40" w:after="40"/></w:pPr>'
            f'<w:r><w:rPr><w:b/><w:color w:val="FFFFFF"/><w:sz w:val="19"/></w:rPr>'
            f'<w:t xml:space="preserve">{html.escape(str(h))}</w:t></w:r></w:p></w:tc>'
        )
    tbl.append("</w:tr>")
    for r_idx, row in enumerate(rows):
        fill = "F4F7FA" if r_idx % 2 == 1 else "FFFFFF"
        tbl.append("<w:tr>")
        for i, val in enumerate(row):
            tbl.append(
                f'<w:tc><w:tcPr><w:tcW w:w="{col_widths[i]}" w:type="dxa"/>'
                f'<w:shd w:val="clear" w:fill="{fill}"/></w:tcPr>'
                f'<w:p><w:pPr><w:spacing w:before="35" w:after="35"/></w:pPr>'
                f'<w:r><w:rPr><w:sz w:val="18"/></w:rPr>'
                f'<w:t xml:space="preserve">{html.escape(str(val))}</w:t></w:r></w:p></w:tc>'
            )
        tbl.append("</w:tr>")
    tbl.append("</w:tbl>")
    body_parts.append("".join(tbl))
    add_p("", space_after=40)

def add_image(img_path, caption, max_w=6.2):
    global rid_counter
    if not os.path.exists(img_path):
        return
    ext = os.path.splitext(img_path)[1].lower().lstrip(".")
    if ext == "jpg":
        ext = "jpeg"
    media_name = f"image{rid_counter}.{ext}"
    rid = f"rIdImg{rid_counter}"
    doc_id = rid_counter
    rid_counter += 1
    with open(img_path, "rb") as f:
        media_files.append((f"word/media/{media_name}", f.read()))
    rel_entries.append(
        f'<Relationship Id="{rid}" '
        f'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" '
        f'Target="media/{media_name}"/>'
    )
    cx, cy = get_img_size_emu(img_path, max_w)
    body_parts.append(
        f'<w:p><w:pPr><w:jc w:val="center"/><w:spacing w:before="80" w:after="40"/></w:pPr>'
        f'<w:r><w:drawing><wp:inline distT="0" distB="0" distL="0" distR="0">'
        f'<wp:extent cx="{cx}" cy="{cy}"/>'
        f'<wp:docPr id="{doc_id}" name="{html.escape(media_name)}"/>'
        f'<a:graphic xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">'
        f'<a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">'
        f'<pic:pic xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">'
        f'<pic:nvPicPr><pic:cNvPr id="{doc_id}" name="{html.escape(media_name)}"/><pic:cNvPicPr/></pic:nvPicPr>'
        f'<pic:blipFill><a:blip r:embed="{rid}"/><a:stretch><a:fillRect/></a:stretch></pic:blipFill>'
        f'<pic:spPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="{cx}" cy="{cy}"/></a:xfrm>'
        f'<a:prstGeom prst="rect"><a:avLst/></a:prstGeom></pic:spPr>'
        f'</pic:pic></a:graphicData></a:graphic></wp:inline></w:drawing></w:r></w:p>'
    )
    add_p(caption, space_after=100, bold=False, color="444444", size_pt=9.5, align="center")

# ==================== DOCUMENT CONTENT ====================
add_p("Project Synopsis — AXI-LiteBurst-32", space_after=40, bold=True, color="1F4E79", size_pt=18, align="center")
add_p("Configurable AXI4-Lite Slave Interface with Custom Burst Extension", space_after=60, bold=True, color="2E75B6", size_pt=13, align="center")
add_p("HCLTech Career Shaper Programme | III Year Industry Project | Academic Year 2025–26", space_after=140, bold=False, color="555555", size_pt=10.5, align="center")

add_table(
    ["Field", "Details"],
    [
        ["Project Title", "AXI-LiteBurst-32: Configurable AXI4-Lite Slave Interface with Burst Extension"],
        ["Project No.", "20"],
        ["Domain", "VLSI / RTL Design"],
        ["Difficulty Level", "Intermediate"],
        ["Duration / Format", "4 Weeks | Individual Project (1 Learner)"],
        ["Learner Name", "Arshad Ali"],
        ["Roll Number", "2400320310043"],
        ["College / Campus", "ABES Engineering College, Ghaziabad"],
        ["Mentor Name", "Mr. Kamal Bhatia"],
        ["Submission Date", "25/11/2026"],
        ["Target FPGA / Clock", "Xilinx Zynq-7000 xc7z020clg400-1 @ 100 MHz (10.000 ns)"],
        ["Source Repository", "https://github.com/Arshad398/AXI_LITEBURST-32_ARSHAD_ALI"],
    ],
    col_widths=[2800, 6560]
)

add_h1("1. Problem Statement")
add_p(
    "Modern System-on-Chip (SoC) and FPGA architectures require efficient, low-latency interconnect communication between processor cores and peripheral register banks without incurring excessive silicon area overhead. "
    "Standard AMBA AXI4-Lite provides a lightweight five-channel control plane, but it lacks native burst transfers—forcing a full address and response handshake for every single 32-bit word during multi-word configuration or block data moves. "
    "Conversely, full AXI4 introduces transaction IDs, out-of-order completion, and complex reordering buffers that consume unnecessary LUTs, flip-flops, and dynamic power in resource-constrained IoT and embedded endpoints. "
    "To bridge this gap, this project designs, implements, and verifies AXI-LiteBurst-32, a modular 32-bit AXI4-Lite-compatible slave IP extended with a controlled 1–16 beat custom burst engine, multi-bank AxPROT[0] address-decode protection, deterministic error reporting (OKAY, SLVERR, DECERR), and glitch-free synchronous low-power clock-enable management."
)

add_h1("2. Proposed Solution & Approach")
add_p(
    "AXI-LiteBurst-32 preserves the standard five-channel AXI4-Lite handshake architecture (AW, W, B, AR, R) while introducing an explicit, documented custom burst extension (s_awlen[3:0], s_awburst[1:0], s_wlast, s_arlen[3:0], s_arburst[1:0], s_rlast). "
    "When AxLEN = 0 and AxBURST = INCR (2'b01), the interface operates identically to a standard single-beat AXI4-Lite slave, ensuring 100% backward compatibility. "
    "Inside the IP, a dual concurrent FSM (axi_slave_fsm) coordinates independent write and read burst_controller engines, allowing simultaneous read and write transactions across isolated register banks (reg_mem_bank) with deterministic write-first same-word collision arbitration. "
    "Address decode protection and byte-lane masking (WSTRB[3:0]) are enforced on every beat, while low_power_controller monitors channel/FSM activity and drives synchronous FPGA FF clock enables (CE) with zero clock-tree glitches."
)

add_h1("3. System Architecture & Module Hierarchy")
add_h2("3.1 Custom Burst Extension & Register Map")
add_table(
    ["Region / Signal", "Range / Width", "Behavior & Protection Policy"],
    [
        ["Bank 0 (General R/W)", "0x00 .. 0x3F (16 words)", "Open R/W (AxPROT[0]=0/1), 1–16 beat FIXED/INCR bursts, WSTRB[3:0] masking"],
        ["Bank 1 (Protected R/W)", "0x40 .. 0x7F (16 words)", "Privileged-only (AxPROT[0]==1 required); unprivileged access -> SLVERR + zeroed RDATA"],
        ["Unmapped Space", "0x80 .. 0xFF (128 bytes)", "Returns DECERR (2'b11); 9-bit burst adder prevents 8-bit wrap-around into Bank 0"],
        ["s_awlen / s_arlen", "4 bits (0..15)", "Custom burst length minus 1 (1..16 beats); 0 = standard single-beat transfer"],
        ["s_awburst / s_arburst", "2 bits", "2'b00 = FIXED, 2'b01 = INCR (+4 bytes/beat); 2'b10/2'b11 -> SLVERR"],
        ["s_wlast / s_rlast", "1 bit", "Burst termination; early/missing WLAST triggers sticky SLVERR without deadlock"],
    ],
    col_widths=[2400, 2200, 4760]
)

add_h2("3.2 Reconciled 14-Module RTL Hierarchy")
add_table(
    ["Module", "Category", "Functional Responsibility"],
    [
        ["axi_liteburst32_top.v", "Top Integration", "122-pin top wrapper integrating all 13 sub-modules (fits <= 125 IOs on xc7z020clg400-1)"],
        ["axi_aw_channel.v", "Write Channel", "Captures AWADDR, AWLEN, AWBURST, AWPROT on AWVALID && AWREADY"],
        ["axi_w_channel.v", "Write Channel", "1-deep streaming WDATA, WSTRB[3:0], WLAST stage (1-beat/cycle + W-first support)"],
        ["axi_b_channel.v", "Write Channel", "Drives BRESP/BVALID and holds stable under BREADY=0 backpressure"],
        ["axi_ar_channel.v", "Read Channel", "Captures ARADDR, ARLEN, ARBURST, ARPROT on ARVALID && ARREADY"],
        ["axi_r_channel.v", "Read Channel", "Drives RDATA, RRESP, RLAST, RVALID and holds stable under RREADY=0 backpressure"],
        ["burst_controller.v", "Burst Engine (x2)", "Tracks beat_index (0..15), +4 address increment, 9-bit overflow guard, bank-cross check"],
        ["address_decoder.v", "Protection (x2)", "Decodes bank_sel & word_index; validates alignment, bounds, and AxPROT[0]"],
        ["response_generator.v", "Response (x2)", "Deterministic priority encoder: DECERR (2'b11) > SLVERR (2'b10) > OKAY (2'b00)"],
        ["write_data_path.v", "Datapath", "Applies WSTRB[3:0] byte-lane masking and suppresses writes on error beats"],
        ["read_data_path.v", "Datapath", "Routes reg_mem_bank read data or forces 32'h0000_0000 on disallowed/error reads"],
        ["reg_mem_bank.v", "Memory", "2 banks x 16 words x 32-bit synchronous register array with CE gating"],
        ["low_power_controller.v", "Power Mgmt", "Activity monitor, IDLE_THRESHOLD counter, glitch-free synchronous clock_enable"],
        ["axi_slave_fsm.v", "Control", "Dual concurrent Write/Read FSM + write-first same-word collision arbiter"],
    ],
    col_widths=[2300, 1700, 5360]
)

add_page_break()
add_h2("3.3 Baseline Vivado RTL Schematics & Device Floorplan (xc7z020clg400-1)")
add_p("The figures below show the Vivado elaborated RTL schematics and post-implementation Zynq-7000 device floorplan captured during the baseline hardware study.")
add_image(os.path.join(BASE, "backup_original", "axi", "device", "WhatsApp Image 2026-11-20 at 12.00.13 PM.jpeg"),
          "Figure 1: Vivado Post-Implementation Device Floorplan (Zynq-7000 xc7z020clg400-1, Clock Region X1Y1)")
add_image(os.path.join(BASE, "backup_original", "axi", "schematics", "WhatsApp Image 2026-11-20 at 11.58.50 AM (6).jpeg"),
          "Figure 2: Vivado Elaborated RTL Schematic — burst_controller")
add_image(os.path.join(BASE, "backup_original", "axi", "schematics", "WhatsApp Image 2026-11-20 at 11.58.50 AM (7).jpeg"),
          "Figure 3: Vivado Elaborated RTL Schematic — low_power_controller")
add_image(os.path.join(BASE, "backup_original", "axi", "schematics", "WhatsApp Image 2026-11-20 at 11.58.50 AM (4).jpeg"),
          "Figure 4: Vivado Elaborated RTL Schematic — axi_w_channel")

add_page_break()
add_h1("4. Technology Stack")
add_table(
    ["Layer / Category", "Tools & Standards Used"],
    [
        ["HDL & Architecture", "Verilog-2001 (14 synthesizable RTL modules, 15 self-checking testbenches)"],
        ["Simulation & Waveform", "Icarus Verilog v12.0 (iverilog -Wall -g2005 + vvp), GTKWave, Vivado XSIM Tcl"],
        ["FPGA EDA & Constraints", "Xilinx Vivado Tcl Automation (scripts/*.tcl) + 100 MHz XDC (xc7z020clg400-1)"],
        ["Data Analytics & EDA", "Python 3.12, pandas, matplotlib, seaborn, Jupyter Notebook"],
        ["Target Hardware", "Xilinx Zynq-7000 xc7z020clg400-1 (53,200 LUTs, 106,400 FFs, 125 IOs, 32 BUFGs)"],
    ],
    col_widths=[2600, 6760]
)

add_h1("5. Dataset Used & Exploratory Data Analysis")
add_p(
    "Note on Dataset Provenance: Project_Brief.docx references an AXI transaction log (trans_id, addr, burst_len, data_width, latency_cycles, error_flag, power_state), while the earlier synopsis template referenced 5,000 rows. "
    "Inspection of the actual supplied dataset.csv confirms it is a 500-row, 9-column synthetic RISC-V instruction trace (pc, instruction_hex, opcode, rs1, rs2, rd, cycles_taken, branch_taken, stall) with 0 missing values and 0 duplicates. "
    "The Python pipeline (analysis/eda_analysis.py) preserves the raw file, outputs dataset/cleaned_dataset.csv (12 columns) and dataset/data_dictionary.csv, and generates four visualizations. "
    "Measured overall metrics: Stall Rate = 12.20% (61/500), Branch Taken Rate = 20.40% (102/500), Mean Execution Latency = 1.540 cycles (median 1.0, max 5)."
)

add_table(
    ["Opcode", "Count", "Share (%)", "Stall Rate (%)", "Mean Cycles", "Branch Rate (%)"],
    [
        ["ADD", "87", "17.4%", "11.49%", "1.51", "20.69%"],
        ["LW",  "73", "14.6%", "5.48%",  "1.62", "17.81%"],
        ["SW",  "58", "11.6%", "17.24%", "1.43", "13.79%"],
        ["SUB", "53", "10.6%", "16.98%", "1.62", "26.42%"],
        ["BEQ", "51", "10.2%", "13.73%", "1.65", "31.37%"],
        ["AND", "50", "10.0%", "10.00%", "1.38", "18.00%"],
        ["OR",  "45", "9.0%",  "11.11%", "1.58", "15.56%"],
        ["XOR", "37", "7.4%",  "10.81%", "1.30", "21.62%"],
        ["LUI", "25", "5.0%",  "16.00%", "1.64", "24.00%"],
        ["JAL", "21", "4.2%",  "14.29%", "1.86", "14.29%"],
    ],
    col_widths=[1400, 1300, 1500, 1720, 1620, 1820]
)

add_image(os.path.join(BASE, "analysis", "visualizations", "01_opcode_frequency_and_share.png"),
          "Figure 5: Instruction Opcode Frequency & Share (N = 500 Rows)")
add_image(os.path.join(BASE, "analysis", "visualizations", "02_stall_rate_by_opcode.png"),
          "Figure 6: Pipeline Stall Rate (%) by Instruction Opcode")
add_image(os.path.join(BASE, "analysis", "visualizations", "03_cycles_taken_distribution.png"),
          "Figure 7: Execution Latency Distribution & Mean Cycles by Opcode")
add_image(os.path.join(BASE, "analysis", "visualizations", "04_branch_and_category_analysis.png"),
          "Figure 8: Instruction Functional Category Mix & Branch Flag Analysis")

add_page_break()
add_h1("6. Key Results & Verification Metrics")
add_h2("6.1 Verified RTL Simulation Regression (Icarus Verilog v12.0)")
add_table(
    ["Verification Target", "Scope", "Result", "Measured Checks / Notes"],
    [
        ["13 Unit Testbenches", "All 13 leaf RTL modules", "13 / 13 PASS", "0 errors; includes newly added tb_axi_aw_channel & fixed .resetn"],
        ["tb_axi_liteburst32_top", "System (TC-01..25, TC-27)", "PASS", "196 scoreboard & assertion checks, 0 errors (9,230 ns)"],
        ["tb_axi_liteburst32_param", "Parameterization (TC-26)", "PASS", "ADDR_WIDTH=10, NUM_BANKS=4, BANK_WORDS=16, 0 errors"],
        ["RTL Elaboration & Lint", "All 14 RTL files (-Wall -g2005)", "PASS", "0 syntax errors, 0 warnings, 122 top-level IOs (<= 125)"],
    ],
    col_widths=[2500, 2300, 1400, 3160]
)

add_h2("6.2 Vivado Synthesis & Implementation Status vs. Historical Baseline")
add_p(
    "Reproducible Vivado Tcl scripts (scripts/create_fresh_project.tcl, run_simulation.tcl, run_synthesis.tcl, run_implementation.tcl) and 100 MHz constraints (constraints/axi_liteburst32_xc7z020.xdc) are prepared for xc7z020clg400-1. "
    "Because Vivado is not installed on the current host, synthesis/PnR execution of the upgraded burst-enabled RTL is pending on a Vivado workstation. "
    "For historical reference only, the earlier Phase 0 unconstrained single-beat baseline screenshots recorded: LUT = 263/53,200 (0.49%), FF = 612/106,400 (0.58%), IO = 110/125 (88.00%), BUFG = 1/32 (3.13%), WNS = inf (unconstrained), and Total On-Chip Power = 5.2 W."
)
add_image(os.path.join(BASE, "backup_original", "axi", "Reports", "WhatsApp Image 2026-11-20 at 11.57.45 AM (2).jpeg"),
          "Figure 9: Baseline Vivado Post-Implementation Resource Utilization (Pre-Burst Reference)")
add_image(os.path.join(BASE, "backup_original", "axi", "Reports", "WhatsApp Image 2026-11-20 at 11.57.45 AM (1).jpeg"),
          "Figure 10: Baseline Vivado Design Timing Summary (Unconstrained Reference)")

add_h1("7. Challenges Faced & How Resolved")
add_bullet("Challenge 1 — Disconnected Burst & FSM Modules in Baseline: ", "Re-architected axi_liteburst32_top.v to instantiate dual burst_controller engines, axi_slave_fsm, and reg_mem_bank with full burst handshakes.")
add_bullet("Challenge 2 — 8-Bit Address Wrap-Around Security Risk: ", "Added a 9-bit extended adder (addr_overflow) in burst_controller.v so bursts near 0xFC cannot wrap into 0x00 and instead return DECERR.")
add_bullet("Challenge 3 — Read/Write Collision & WLAST Deadlock: ", "Implemented write-first same-word collision arbitration and early/missing WLAST recovery in axi_slave_fsm.v.")
add_bullet("Challenge 4 — I/O Pin Budget on xc7z020clg400-1: ", "Sized top-level ports cleanly to 122 I/O pins, fitting within the 125 available package pins.")

add_h1("8. References")
add_p("1. ARM Limited, \"AMBA AXI and ACE Protocol Specification (AXI3, AXI4, and AXI4-Lite)\", ARM IHI 0022E.")
add_p("2. AMD Xilinx, \"Vivado Design Suite User Guide: Synthesis (UG901)\" and \"Using Constraints (UG903)\".")
add_p("3. HCLTech Career Shaper Programme Guidelines, \"Project 20: AXI-LiteBurst-32\", Academic Year 2025–26.")

add_h1("9. Ethical Compliance Declaration")
add_p("[x] All dataset and source code usage complies with open-source and institutional software licensing.")
add_p("[x] No personally identifiable information (PII) is stored or processed.")
add_p("[x] AI engineering tools used for RTL structuring, verification, and documentation are disclosed.")
add_p("[x] This project complies with applicable digital data protection standards (DPDP Act 2023).")
add_p("[x] AXI slave implements address decode and AxPROT[0] privilege protection to prevent unauthorized memory-mapped register access.")
add_p("Learner Signature: _________________________ (Arshad Ali)        Date: 25/11/2026", space_before=120, bold=True)

add_page_break()
add_h1("Appendix A: Simulation Waveforms")
add_p("Selected Vivado XSIM baseline waveforms and full system verification captures:")
add_image(os.path.join(BASE, "backup_original", "axi", "simulation", "WhatsApp Image 2026-11-20 at 11.56.17 AM.jpeg"),
          "Figure A1: System Top-Level Waveform — tb_axi_liteburst32_top")
add_image(os.path.join(BASE, "backup_original", "axi", "simulation", "WhatsApp Image 2026-11-20 at 11.56.17 AM (3).jpeg"),
          "Figure A2: Burst Controller Waveform — tb_burst_controller")
add_image(os.path.join(BASE, "backup_original", "axi", "simulation", "WhatsApp Image 2026-11-20 at 11.56.17 AM (4).jpeg"),
          "Figure A3: Low-Power Controller Waveform — tb_low_power_controller")
add_image(os.path.join(BASE, "backup_original", "axi", "simulation", "WhatsApp Image 2026-11-20 at 11.56.18 AM.jpeg"),
          "Figure A4: Register Memory Bank Waveform — tb_reg_mem_bank")

# ==================== WRITE DOCX PACKAGE ====================
doc_xml = (
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" '
    'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" '
    'xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing">'
    f'<w:body>{"".join(body_parts)}'
    '<w:sectPr><w:pgSz w:w="12240" w:h="15840"/>'
    '<w:pgMar w:top="900" w:right="900" w:bottom="900" w:left="900"/></w:sectPr>'
    '</w:body></w:document>'
)

content_types = (
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
    '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
    '<Default Extension="xml" ContentType="application/xml"/>'
    '<Default Extension="png" ContentType="image/png"/>'
    '<Default Extension="jpeg" ContentType="image/jpeg"/>'
    '<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>'
    '</Types>'
)

root_rels = (
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
    '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>'
    '</Relationships>'
)

doc_rels = (
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
    f'{"".join(rel_entries)}'
    '</Relationships>'
)

with zipfile.ZipFile(OUT_DOCX, "w", zipfile.ZIP_DEFLATED) as z:
    z.writestr("[Content_Types].xml", content_types)
    z.writestr("_rels/.rels", root_rels)
    z.writestr("word/_rels/document.xml.rels", doc_rels)
    z.writestr("word/document.xml", doc_xml)
    for m_path, m_bytes in media_files:
        z.writestr(m_path, m_bytes)

print("Built:", OUT_DOCX, "Size:", os.path.getsize(OUT_DOCX), "Images embedded:", len(media_files))
