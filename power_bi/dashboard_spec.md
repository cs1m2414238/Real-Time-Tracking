# Power BI Dashboard Design & Architecture Specification

## 1. Data Model (Star Schema)

The Power BI data model follows an industry-standard dimensional star schema:

```
                  +---------------------------+
                  |         Dim_Bases         |
                  |---------------------------|
                  | Base_ID (PK)              |
                  | Base_Name                 |
                  | Region                    |
                  | Strategic_Role            |
                  | Target_Readiness          |
                  +-------------+-------------+
                                | 1
                                |
                                | *
+---------------------------+   |   +---------------------------+
|    Dim_Equipment_Types    |   |   |        Dim_Calendar       |
|---------------------------|   |   |---------------------------|
| Type_ID (PK)              |   |   | Date (PK)                 |
| Equipment_Type            |   |   | Year, Month, MonthName    |
| Category                  |   |   | Quarter, WeekNumber       |
| Fuel_Burn_Rate_L_Hr       |   |   | FiscalPeriod              |
| Service_Interval_Days     |   |   +-------------+-------------+
+-------------+-------------+   |                 | 1
              | 1               |                 |
              | *               |                 | *
  +-----------+-----------------+-----------------+-----------+
  |                 Fact_Equipment_Inventory                  |
  |-----------------------------------------------------------|
  | Equipment_ID (PK)                                         |
  | Base_ID (FK) -> Dim_Bases.Base_ID                         |
  | Type_ID (FK) -> Dim_Equipment_Types.Type_ID               |
  | Last_Service_Date (FK) -> Dim_Calendar.Date               |
  | Next_Service_Date (FK) -> Dim_Calendar.Date               |
  | Status (Operational, Maintenance, Out of Service)         |
  | Operating_Hours, Fuel_Used_L, Maintenance_Cost_INR        |
  | Spare_Parts (Available, Low, Critical Shortage)           |
  | Readiness_Pct, Downtime_Days, Is_Critical                 |
  +-----------------------------------------------------------+
                                | 1
                                |
                                | *
                  +-------------+-------------+
                  |   Fact_Maintenance_Logs   |
                  |---------------------------|
                  | Log_ID (PK)               |
                  | Equipment_ID (FK)         |
                  | Base_ID (FK)              |
                  | Service_Date, Cost_INR    |
                  | Labor_Hours, Parts_Used   |
                  +---------------------------+
```

### Relationship Properties:
- `Dim_Bases[Base_ID]` `1` : `*` `Fact_Equipment_Inventory[Base_ID]` (Single Direction)
- `Dim_Equipment_Types[Type_ID]` `1` : `*` `Fact_Equipment_Inventory[Type_ID]` (Single Direction)
- `Dim_Calendar[Date]` `1` : `*` `Fact_Equipment_Inventory[Next_Service]` (Active)
- `Dim_Calendar[Date]` `1` : `*` `Fact_Equipment_Inventory[Last_Service]` (Inactive, activated via `USERELATIONSHIP`)
- `Fact_Equipment_Inventory[Equipment_ID]` `1` : `*` `Fact_Maintenance_Logs[Equipment_ID]` (Single Direction)

---

## 2. Visual Layout Specification (Command & Control Grid)

### Top Section: Executive KPI Cards (Row 1)
| Card Visual | Measure | Value Format | Benchmark Callout |
| :--- | :--- | :--- | :--- |
| **Total Fleet** | `[Total Equipment]` | `1,250` | 8 Strategic Bases |
| **Operational Fleet** | `[Operational Equipment]` | `1,037` | Target: >1,020 units |
| **Readiness Rate** | `[Readiness Rate]` | `83.0%` | Color alert (<80% Red, >=85% Green) |
| **Under Maintenance** | `[Under Maintenance]` | `146 units` | 11.7% of total fleet |
| **Critical Assets** | `[Critical Equipment]` | `67 units` | Readiness <60% |
| **Total Maint Expenditure**| `[Total Maintenance Cost]`| `₹18.4L` | Avg ₹14.7k / unit |

---

### Middle Section: Core Operational Visuals (Row 2)

#### Visual 1: Base Operational Readiness vs. Target (Clustered Bar / Bullet Chart)
- **Y-Axis**: `Dim_Bases[Base_Name]` (Delhi, Lucknow, Pune, Leh, Jodhpur, Siliguri, Bhopal, Kanpur)
- **X-Axis**: `[Readiness Rate]`
- **Target Line**: `Dim_Bases[Target_Readiness]`
- **Data Callouts**:
  - Delhi (93.1%), Lucknow (91.2%) -> Exceeding Targets
  - Bhopal (78.3%), Kanpur (74.2%) -> Below Strategic Thresholds (Red alert conditional fill)

#### Visual 2: Equipment Status Breakdown (Donut Chart)
- **Legend**: `Fact_Equipment_Inventory[Status]` (Operational: 83.0%, Maintenance: 11.7%, Out of Service: 5.3%)
- **Data Value**: `[Total Equipment]`

#### Visual 3: Monthly Maintenance Cost Trend (Line Chart with 3-Month Moving Average)
- **X-Axis**: `Dim_Calendar[MonthName]` (Jan to Dec)
- **Y-Axis**: `[Total Maintenance Cost]`, `[Prior Month Maintenance Cost]`
- **Highlight**: Visual callout on Generator cost spike in Q2/Q3.

---

### Bottom Section: Tactical Operations & Maintenance Triage (Row 3)

#### Visual 4: Upcoming Maintenance Service Horizon (Stacked Bar Chart)
- **Categories**:
  - `Overdue Service` (24 assets)
  - `Next 7 Days` (68 assets)
  - `Next 30 Days` (215 assets)
  - `Next 60 Days` (340 assets)
- **Segment Color**: Split by `Spare_Parts` (Green: Available, Amber: Low, Red: Critical Shortage)

#### Visual 5: Slicers & Global Interactive Filters
- **Base Slicer**: Multi-select dropdown (`Lucknow`, `Kanpur`, `Bhopal`, `Delhi`, `Leh`, `Jodhpur`, `Siliguri`, `Pune`)
- **Equipment Type Slicer**: Multi-select pill buttons (`Heavy Tactical Truck`, `Armored Personnel Carrier`, `Field Diesel Generator`, `Tactical UAV Launcher`, `Mobile Radar Unit`, `Artillery Tractor`)
- **Operational Status Slicer**: `Operational` | `Maintenance` | `Out of Service`
- **Readiness Threshold Slider**: Range slider (0% to 100%)
