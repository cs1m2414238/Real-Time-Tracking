import os
import pandas as pd

base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
data_dir = os.path.join(base_dir, "data")
sql_dir = os.path.join(base_dir, "sql")
os.makedirs(sql_dir, exist_ok=True)

df_clean = pd.read_csv(os.path.join(data_dir, 'fact_equipment_inventory.csv'))
df_bases = pd.read_csv(os.path.join(data_dir, 'dim_bases.csv'))
df_types = pd.read_csv(os.path.join(data_dir, 'dim_equipment_types.csv'))
df_logs = pd.read_csv(os.path.join(data_dir, 'fact_maintenance_logs.csv'))

seed_path = os.path.join(sql_dir, '02_seed_data.sql')

with open(seed_path, 'w', encoding='utf-8') as f:
    f.write('-- ============================================================================\n')
    f.write('-- SEED DATA FOR MILITARY LOGISTICS DATABASE\n')
    f.write('-- ============================================================================\n\n')
    
    f.write('-- 1. Dim Bases\n')
    for _, r in df_bases.iterrows():
        f.write(f"INSERT INTO dim_bases (base_id, base_name, region, strategic_role, commander_rank, target_readiness) VALUES ('{r.Base_ID}', '{r.Base_Name}', '{r.Region}', '{r.Strategic_Role}', '{r.Commander_Rank}', {r.Target_Readiness});\n")
    
    f.write('\n-- 2. Dim Equipment Types\n')
    for _, r in df_types.iterrows():
        f.write(f"INSERT INTO dim_equipment_types (type_id, equipment_type, category, fuel_burn_rate_l_hr, service_interval_days, base_cost_inr) VALUES ('{r.Type_ID}', '{r.Equipment_Type}', '{r.Category}', {r.Fuel_Burn_Rate_L_Hr}, {r.Service_Interval_Days}, {r.Base_Cost_INR});\n")
    
    f.write('\n-- 3. Fact Equipment Inventory\n')
    for _, r in df_clean.iterrows():
        f.write(f"INSERT INTO fact_equipment_inventory (equipment_id, base_id, base_name, type_id, equipment_type, category, status, last_service_date, next_service_date, fuel_used_l, operating_hours, maintenance_cost_inr, spare_parts_status, readiness_pct, downtime_days, is_critical) VALUES ('{r.Equipment_ID}', '{r.Base_ID}', '{r.Base}', '{r.Type_ID}', '{r.Equipment_Type}', '{r.Category}', '{r.Status}', '{r.Last_Service}', '{r.Next_Service}', {r.Fuel_Used_L}, {r.Operating_Hours}, {r.Maintenance_Cost_INR}, '{r.Spare_Parts}', {r.Readiness_Pct}, {r.Downtime_Days}, {r.Is_Critical});\n")
    
    f.write('\n-- 4. Fact Maintenance Logs (Sample of recent service events)\n')
    for _, r in df_logs.head(1000).iterrows():
        parts = str(r.Parts_Replaced).replace("'", "''")
        f.write(f"INSERT INTO fact_maintenance_logs (log_id, equipment_id, base_id, service_date, service_type, technician_rank, labor_hours, parts_replaced, cost_inr, downtime_days) VALUES ('{r.Log_ID}', '{r.Equipment_ID}', '{r.Base_ID}', '{r.Service_Date}', '{r.Service_Type}', '{r.Technician_Rank}', {r.Labor_Hours}, '{parts}', {r.Cost_INR}, {r.Downtime_Days});\n")

print(f"Successfully generated {seed_path}")
