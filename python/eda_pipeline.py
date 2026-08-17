"""
Military Logistics & Readiness: Exploratory Data Analysis & Cleaning Pipeline
Technology: Python (Pandas, NumPy, Matplotlib, Seaborn)
Demonstrates data validation, dirty data cleaning, statistical modeling, and publication-grade charting.
"""

import os
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

# Configure visual style
sns.set_theme(style="whitegrid", palette="muted")
plt.rcParams["font.family"] = "sans-serif"
plt.rcParams["font.sans-serif"] = ["Segoe UI", "DejaVu Sans", "Arial"]

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR = os.path.join(BASE_DIR, "data")
OUTPUT_DIR = os.path.join(BASE_DIR, "python", "output")
os.makedirs(OUTPUT_DIR, exist_ok=True)

def run_eda_pipeline():
    print("=" * 70)
    print("MILITARY LOGISTICS & READINESS EDA PIPELINE")
    print("=" * 70)
    
    # -------------------------------------------------------------------------
    # STEP 1: Dirty Data Audit & Cleaning Demonstration
    # -------------------------------------------------------------------------
    dirty_path = os.path.join(DATA_DIR, "raw_equipment_dirty.csv")
    df_raw = pd.read_csv(dirty_path)
    print(f"\n[1] Raw Ingestion Audit:")
    print(f" - Raw Record Count: {len(df_raw)}")
    print(f" - Duplicate Equipment IDs: {df_raw['Equipment_ID'].duplicated().sum()}")
    print(f" - Missing Values per Column:\n{df_raw.isnull().sum()}")
    
    # Cleaning pipeline
    df_clean_sim = df_raw.drop_duplicates(subset=["Equipment_ID"]).copy()
    df_clean_sim["Base"] = df_clean_sim["Base"].str.strip().str.title()
    df_clean_sim["Equipment_Type"] = df_clean_sim["Equipment_Type"].str.strip().str.title().str.replace("_", " ")
    df_clean_sim["Spare_Parts"] = df_clean_sim["Spare_Parts"].fillna("Available")
    
    # Clean currency strings
    if df_clean_sim["Maintenance_Cost"].dtype == object:
        df_clean_sim["Maintenance_Cost"] = (
            df_clean_sim["Maintenance_Cost"]
            .astype(str)
            .str.replace("₹", "", regex=False)
            .str.replace("INR", "", regex=False)
            .str.replace("Rs.", "", regex=False)
            .str.replace(",", "", regex=False)
            .str.strip()
            .astype(float)
        )
    print(f"\n[2] Cleaned Simulation Record Count: {len(df_clean_sim)} (Duplicates Removed & Types Standardized)")

    # -------------------------------------------------------------------------
    # STEP 2: Ingest Master Clean Inventory for Deep Analytics
    # -------------------------------------------------------------------------
    clean_path = os.path.join(DATA_DIR, "fact_equipment_inventory.csv")
    df = pd.read_csv(clean_path)
    
    print(f"\n[3] Master Dataset Overview (N = {len(df)}):")
    print(f" - Fleet Operational Readiness: {(df['Status'] == 'Operational').mean() * 100:.1f}%")
    print(f" - Mean Readiness Score: {df['Readiness_Pct'].mean():.2f}%")
    print(f" - Total Fleet Maintenance Cost: INR {df['Maintenance_Cost_INR'].sum():,}")
    print(f" - Critical Assets (<60% Readiness): {(df['Readiness_Pct'] < 60).sum()} units")
    
    # Base Level Breakdown
    base_summary = df.groupby("Base").agg(
        Total_Equipment=("Equipment_ID", "count"),
        Operational_Units=("Status", lambda x: (x == "Operational").sum()),
        Avg_Readiness=("Readiness_Pct", "mean"),
        Avg_Cost=("Maintenance_Cost_INR", "mean"),
        Avg_Downtime=("Downtime_Days", "mean")
    ).reset_index()
    base_summary["Readiness_Rate_Pct"] = (base_summary["Operational_Units"] / base_summary["Total_Equipment"]) * 100
    base_summary = base_summary.sort_values(by="Readiness_Rate_Pct", ascending=False)
    
    print(f"\n[4] Base Readiness Performance Table:\n{base_summary.to_string(index=False)}")

    # -------------------------------------------------------------------------
    # STEP 3: Generate High-Resolution Visualizations
    # -------------------------------------------------------------------------
    
    # 1. Base Readiness vs Target Bar Chart
    plt.figure(figsize=(10, 5.5), dpi=300)
    palette = ["#10B981" if r >= 85 else "#F59E0B" if r >= 78 else "#EF4444" for r in base_summary["Readiness_Rate_Pct"]]
    ax = sns.barplot(
        data=base_summary,
        x="Base",
        y="Readiness_Rate_Pct",
        palette=palette,
        hue="Base",
        legend=False
    )
    plt.axhline(85, color="#64748B", linestyle="--", linewidth=1.5, label="Standard Target (85%)")
    plt.title("Fleet Operational Readiness Rate by Military Base", fontsize=14, fontweight="bold", pad=15, color="#0F172A")
    plt.xlabel("Military Base", fontsize=11, fontweight="bold", color="#334155")
    plt.ylabel("Operational Readiness Rate (%)", fontsize=11, fontweight="bold", color="#334155")
    plt.ylim(0, 105)
    
    for p in ax.patches:
        height = p.get_height()
        if height > 0:
            ax.annotate(f"{height:.1f}%",
                        (p.get_x() + p.get_width() / 2., height),
                        ha='center', va='bottom', fontsize=10, fontweight='bold', color='#1E293B',
                        xytext=(0, 3), textcoords='offset points')
            
    plt.legend(loc="lower right")
    plt.tight_layout()
    chart1_path = os.path.join(OUTPUT_DIR, "readiness_by_base.png")
    plt.savefig(chart1_path)
    plt.close()
    print(f" - Exported: {chart1_path}")

    # 2. Scatter Plot: Maintenance Cost vs Operating Hours with Risk Quadrants
    plt.figure(figsize=(10, 6), dpi=300)
    scatter = sns.scatterplot(
        data=df,
        x="Operating_Hours",
        y="Maintenance_Cost_INR",
        hue="Readiness_Pct",
        size="Downtime_Days",
        sizes=(30, 260),
        palette="RdYlGn",
        alpha=0.85,
        edgecolor="black",
        linewidth=0.5
    )
    
    # Benchmarks
    avg_hours = df["Operating_Hours"].mean()
    avg_cost = df["Maintenance_Cost_INR"].mean()
    plt.axvline(avg_hours, color="#64748B", linestyle="--", alpha=0.7, label=f"Avg Hours ({avg_hours:.0f}h)")
    plt.axhline(avg_cost, color="#64748B", linestyle="--", alpha=0.7, label=f"Avg Cost (INR {avg_cost:,.0f})")
    
    # Annotate Problem Zone
    plt.text(df["Operating_Hours"].max() - 120, df["Maintenance_Cost_INR"].max() - 8000, 
             "CRITICAL ASSET ZONE\n(High Hours, High Cost, Low Readiness)", 
             fontsize=9, fontweight="bold", color="#991B1B",
             bbox=dict(boxstyle="round,pad=0.5", facecolor="#FEE2E2", edgecolor="#DC2626", alpha=0.9))
             
    plt.title("Equipment Risk Matrix: Maintenance Cost vs. Operating Hours", fontsize=14, fontweight="bold", pad=15, color="#0F172A")
    plt.xlabel("Operating Hours Logged", fontsize=11, fontweight="bold", color="#334155")
    plt.ylabel("Maintenance Cost (INR)", fontsize=11, fontweight="bold", color="#334155")
    plt.legend(bbox_to_anchor=(1.02, 1), loc='upper left', borderaxespad=0)
    plt.tight_layout()
    chart2_path = os.path.join(OUTPUT_DIR, "cost_vs_hours_scatter.png")
    plt.savefig(chart2_path)
    plt.close()
    print(f" - Exported: {chart2_path}")

    # 3. Spare Parts Bottleneck vs Downtime Impact
    plt.figure(figsize=(8.5, 5), dpi=300)
    spares_agg = df.groupby("Spare_Parts").agg(
        Avg_Downtime=("Downtime_Days", "mean"),
        Avg_Readiness=("Readiness_Pct", "mean"),
        Count=("Equipment_ID", "count")
    ).reindex(["Available", "Low", "Critical Shortage"])
    
    colors = ["#10B981", "#F59E0B", "#EF4444"]
    ax_sp = sns.barplot(x=spares_agg.index, y=spares_agg["Avg_Downtime"], palette=colors, hue=spares_agg.index, legend=False)
    plt.title("Impact of Spare Parts Availability on Equipment Downtime", fontsize=13, fontweight="bold", pad=15, color="#0F172A")
    plt.xlabel("Spare Parts Supply Chain Status", fontsize=11, fontweight="bold", color="#334155")
    plt.ylabel("Average Downtime (Days)", fontsize=11, fontweight="bold", color="#334155")
    
    for p in ax_sp.patches:
        height = p.get_height()
        ax_sp.annotate(f"{height:.1f} Days",
                      (p.get_x() + p.get_width() / 2., height),
                      ha='center', va='bottom', fontsize=10, fontweight='bold', color='#1E293B',
                      xytext=(0, 3), textcoords='offset points')
                      
    plt.tight_layout()
    chart3_path = os.path.join(OUTPUT_DIR, "spares_impact_analysis.png")
    plt.savefig(chart3_path)
    plt.close()
    print(f" - Exported: {chart3_path}")
    
    print("\n[5] EDA Pipeline successfully executed and all figures saved.")

if __name__ == "__main__":
    run_eda_pipeline()
