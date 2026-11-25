"""
EDA and Data Cleaning Pipeline for AXI-LiteBurst-32 (Phase 7)
Processes the supplied 500-row RISC-V instruction trace (dataset/dataset.csv),
generates cleaned_dataset.csv, data_dictionary.csv, summary statistics, and 4 visualizations.
"""
import os
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import seaborn as sns

BASE_DIR = r"d:\hcl project axi liteburst"
RAW_PATH = os.path.join(BASE_DIR, "dataset", "dataset.csv")
CLEAN_PATH = os.path.join(BASE_DIR, "dataset", "cleaned_dataset.csv")
DICT_PATH = os.path.join(BASE_DIR, "dataset", "data_dictionary.csv")
VIZ_DIR = os.path.join(BASE_DIR, "analysis", "visualizations")
os.makedirs(VIZ_DIR, exist_ok=True)

df = pd.read_csv(RAW_PATH)
print(f"Loaded raw dataset: {df.shape[0]} rows, {df.shape[1]} columns")
print("Missing values per column:\n", df.isna().sum().to_dict())
print("Duplicate rows:", int(df.duplicated().sum()))

# Validate types and ranges
df["pc_decimal"] = df["pc"].apply(lambda x: int(str(x), 16))
df["instruction_uint32"] = df["instruction_hex"].apply(lambda x: int(str(x), 16))
df["rs1"] = df["rs1"].astype(int)
df["rs2"] = df["rs2"].astype(int)
df["rd"] = df["rd"].astype(int)
df["cycles_taken"] = df["cycles_taken"].astype(int)
df["branch_taken"] = df["branch_taken"].astype(int)
df["stall"] = df["stall"].astype(int)

cat_map = {
    "ADD": "ALU", "SUB": "ALU", "AND": "ALU", "OR": "ALU", "XOR": "ALU", "LUI": "ALU",
    "LW": "Memory", "SW": "Memory",
    "BEQ": "Control", "JAL": "Control",
}
df["instr_category"] = df["opcode"].map(cat_map).fillna("Other")
df.to_csv(CLEAN_PATH, index=False)
print(f"Saved cleaned dataset to {CLEAN_PATH}")

# Generate complete data_dictionary.csv
descriptions = {
    "pc": ("string (hex)", "Program counter byte address of the instruction (0x00000000 to 0x000007CC)"),
    "instruction_hex": ("string (hex)", "32-bit instruction word in hexadecimal representation"),
    "opcode": ("categorical", "RISC-V instruction mnemonic (ADD, SUB, AND, OR, XOR, LUI, LW, SW, BEQ, JAL)"),
    "rs1": ("int64", "Source register 1 index (0-31)"),
    "rs2": ("int64", "Source register 2 index (0-31)"),
    "rd": ("int64", "Destination register index (0-31)"),
    "cycles_taken": ("int64", "Execution latency in clock cycles (1-5)"),
    "branch_taken": ("int64 (binary)", "Branch taken indicator (1 = taken, 0 = not taken)"),
    "stall": ("int64 (binary)", "Pipeline stall indicator (1 = stalled, 0 = no stall)"),
    "pc_decimal": ("int64 (derived)", "Integer byte offset converted from hexadecimal pc"),
    "instruction_uint32": ("int64 (derived)", "Unsigned 32-bit integer value of instruction_hex"),
    "instr_category": ("categorical (derived)", "Instruction functional class: ALU, Memory, or Control"),
}
dict_rows = []
for col in df.columns:
    dtype_str, desc = descriptions[col]
    samples = df[col].head(3).tolist()
    dict_rows.append({
        "column_name": col,
        "data_type": dtype_str,
        "sample_value_1": samples[0],
        "sample_value_2": samples[1],
        "sample_value_3": samples[2],
        "nullable": "No" if df[col].isna().sum() == 0 else "Yes",
        "description": desc,
    })
pd.DataFrame(dict_rows).to_csv(DICT_PATH, index=False)
print(f"Saved data dictionary to {DICT_PATH}")

# Print exact summary stats
print("\n=== SUMMARY STATISTICS ===")
print(f"Overall stall rate: {df['stall'].mean()*100:.2f}% ({df['stall'].sum()}/{len(df)})")
print(f"Overall branch taken rate: {df['branch_taken'].mean()*100:.2f}% ({df['branch_taken'].sum()}/{len(df)})")
print(f"Mean cycles_taken: {df['cycles_taken'].mean():.3f}, Median: {df['cycles_taken'].median():.1f}, Max: {df['cycles_taken'].max()}")
op_stats = df.groupby("opcode").agg(
    count=("opcode", "count"),
    share_pct=("opcode", lambda s: len(s) / len(df) * 100.0),
    stall_rate_pct=("stall", lambda s: s.mean() * 100.0),
    mean_cycles=("cycles_taken", "mean"),
    branch_rate_pct=("branch_taken", lambda s: s.mean() * 100.0),
).sort_values("count", ascending=False)
print(op_stats.round(2).to_string())

sns.set_theme(style="whitegrid", context="notebook")

# Chart 1: Opcode Frequency & Share
fig, ax = plt.subplots(figsize=(9, 5))
order = op_stats.index.tolist()
sns.barplot(x=order, y=op_stats["count"].values, hue=order, palette="viridis", legend=False, ax=ax)
for idx, val in enumerate(op_stats["count"].values):
    ax.text(idx, val + 1.5, f"{val}\n({val/len(df)*100:.1f}%)", ha="center", va="bottom", fontsize=9)
ax.set_title("Instruction Opcode Frequency Distribution (N = 500 Rows)")
ax.set_xlabel("Instruction Opcode")
ax.set_ylabel("Row Count")
ax.set_ylim(0, op_stats["count"].max() * 1.18)
plt.tight_layout()
plt.savefig(os.path.join(VIZ_DIR, "01_opcode_frequency_and_share.png"), dpi=150)
plt.close()

# Chart 2: Stall Rate by Opcode
fig, ax = plt.subplots(figsize=(9, 5))
stall_sorted = op_stats.sort_values("stall_rate_pct", ascending=False)
sns.barplot(x=stall_sorted.index, y=stall_sorted["stall_rate_pct"].values, hue=stall_sorted.index, palette="magma", legend=False, ax=ax)
ax.axhline(df["stall"].mean() * 100.0, color="red", linestyle="--", linewidth=1.5, label=f"Overall Mean ({df['stall'].mean()*100:.1f}%)")
for idx, val in enumerate(stall_sorted["stall_rate_pct"].values):
    ax.text(idx, val + 0.6, f"{val:.1f}%", ha="center", va="bottom", fontsize=9)
ax.set_title("Pipeline Stall Rate (%) by Instruction Opcode")
ax.set_xlabel("Instruction Opcode")
ax.set_ylabel("Stall Rate (%)")
ax.set_ylim(0, max(stall_sorted["stall_rate_pct"].max() * 1.2, 10))
ax.legend()
plt.tight_layout()
plt.savefig(os.path.join(VIZ_DIR, "02_stall_rate_by_opcode.png"), dpi=150)
plt.close()

# Chart 3: Cycles Taken Distribution & Mean by Opcode
fig, axes = plt.subplots(1, 2, figsize=(12, 4.8))
cyc_counts = df["cycles_taken"].value_counts().sort_index()
sns.barplot(x=cyc_counts.index.astype(str), y=cyc_counts.values, hue=cyc_counts.index.astype(str), palette="crest", legend=False, ax=axes[0])
for idx, val in enumerate(cyc_counts.values):
    axes[0].text(idx, val + 5, str(val), ha="center", va="bottom", fontsize=9)
axes[0].set_title("Distribution of Execution Latency (cycles_taken)")
axes[0].set_xlabel("Cycles Taken")
axes[0].set_ylabel("Instruction Count")
axes[0].set_ylim(0, cyc_counts.max() * 1.15)

cyc_sorted = op_stats.sort_values("mean_cycles", ascending=False)
sns.barplot(x=cyc_sorted.index, y=cyc_sorted["mean_cycles"].values, hue=cyc_sorted.index, palette="rocket", legend=False, ax=axes[1])
axes[1].set_title("Mean Execution Cycles by Opcode")
axes[1].set_xlabel("Instruction Opcode")
axes[1].set_ylabel("Mean Cycles Taken")
axes[1].tick_params(axis="x", rotation=35)
plt.tight_layout()
plt.savefig(os.path.join(VIZ_DIR, "03_cycles_taken_distribution.png"), dpi=150)
plt.close()

# Chart 4: Category Share & Branch Behavior
fig, axes = plt.subplots(1, 2, figsize=(12, 4.8))
cat_counts = df["instr_category"].value_counts()
axes[0].pie(cat_counts.values, labels=cat_counts.index, autopct="%1.1f%%", startangle=140, colors=sns.color_palette("Set2", len(cat_counts)))
axes[0].set_title("Instruction Mix by Functional Category")

br_sorted = op_stats.sort_values("branch_rate_pct", ascending=False)
sns.barplot(x=br_sorted.index, y=br_sorted["branch_rate_pct"].values, hue=br_sorted.index, palette="flare", legend=False, ax=axes[1])
axes[1].set_title("Branch Taken Flag Rate (%) by Opcode")
axes[1].set_xlabel("Instruction Opcode")
axes[1].set_ylabel("Branch Taken (%)")
axes[1].tick_params(axis="x", rotation=35)
plt.tight_layout()
plt.savefig(os.path.join(VIZ_DIR, "04_branch_and_category_analysis.png"), dpi=150)
plt.close()

print("Generated 4 visualizations in", VIZ_DIR)
