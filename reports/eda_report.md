# EDA Report — AXI-LiteBurst-32 (Phase 7)

**Raw Dataset:** `dataset/dataset.csv` (500 rows, 9 columns, preserved unmodified)  
**Cleaned Dataset:** `dataset/cleaned_dataset.csv` (500 rows, 12 columns)  
**Data Dictionary:** `dataset/data_dictionary.csv`  
**Scripts & Notebook:** `analysis/eda_analysis.py`, `analysis/eda_analysis.ipynb`

## 1. Dataset Provenance & Discrepancy Note
- `Project_Brief.docx` describes an AXI transaction log (`trans_id, addr, burst_len, data_width, latency_cycles, error_flag, power_state`).
- The Synopsis describes a 5,000-row RISC-V instruction trace.
- The actual supplied `dataset.csv` is a **500-row, 9-column RISC-V instruction trace** with **0 missing values** and **0 duplicate rows**. All statistics and charts below are derived strictly from these 500 supplied rows.

## 2. Measured Summary Statistics
- **Total Instructions:** `500` (`ALU: 59.4%`, `Memory (LW/SW): 26.2%`, `Control (BEQ/JAL): 14.4%`)
- **Overall Stall Rate:** `12.20%` (`61 / 500`)
- **Overall Branch Taken Rate:** `20.40%` (`102 / 500`)
- **Execution Latency (`cycles_taken`):** Mean = `1.540`, Median = `1.0`, Range = `1..5`
- **Highest-Count Opcode:** `ADD` (`87` rows, `17.4%`)
- **Highest-Stall Opcode:** `SW` (`17.24%`), followed by `SUB` (`16.98%`) and `LUI` (`16.00%`)
- **Synthetic Trace Observation:** Non-control instructions (`ADD`, `LW`, `SW`, `SUB`, `AND`, `OR`, `XOR`, `LUI`) carry non-zero `branch_taken` flags (`13.79%–26.42%`), confirming the trace is synthetically generated.

## 3. Generated Visualizations (`analysis/visualizations/`)
1. `01_opcode_frequency_and_share.png`
2. `02_stall_rate_by_opcode.png`
3. `03_cycles_taken_distribution.png`
4. `04_branch_and_category_analysis.png`
