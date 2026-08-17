# Tableau Dashboard: Equipment Maintenance Risk Analysis

## Executive Objective
Complement the Power BI operational monitoring dashboard with a focused **Asset Risk & Maintenance Anomaly** Tableau dashboard.

The centerpiece is the **Maintenance Cost vs. Operating Hours Risk Matrix**, designed to isolate high-wear, high-cost, and low-readiness equipment requiring immediate overhaul or decommissioning.

---

## 1. Visual Architecture: Maintenance Cost vs Operating Hours Scatter Plot

```
 Maintenance Cost (₹)
      ^
 High |  [ QUADRANT 2: Cost Inefficient ]    |    [ QUADRANT 1: HIGH PROBLEM ASSETS ]
      |  (Moderate hours, excessive repairs) |    (High hours + High Cost + Low Readiness)
      |  * e.g., Failing generators          |    * Immediate Overhaul Required
      |                                      |
  Avg +--------------------------------------+----------------------------------------
      |  [ QUADRANT 3: Healthy Baseline ]    |    [ QUADRANT 4: High-Duty Workhorses ]
      |  (Low hours, low maintenance cost)   |    (High utilization, well maintained)
  Low |  * Standard inventory                |    * Monitor for upcoming wear cycle
      +-------------------------------------------------------------------------------->
      Low                                  Avg                                      High
                                     Operating Hours
```

### Encoding Specifications:
- **X-Axis (Columns)**: `SUM([Operating_Hours])`
- **Y-Axis (Rows)**: `SUM([Maintenance_Cost_INR])`
- **Detail (Marks)**: `[Equipment_ID]`
- **Color (Hue)**: `AVG([Readiness_Pct])` using diverging palette **Red-Yellow-Green** (Stepped 5 classes: <50% Deep Red, 50-65% Coral, 65-80% Amber, 80-90% Light Green, >90% Emerald).
- **Size**: `SUM([Downtime_Days])` (Larger bubbles represent chronic downtime).
- **Shape**: `[Status]` (Circle: Operational, Square: Maintenance, Cross: Out of Service).

---

## 2. Tableau Calculated Fields

### A. Asset Risk Tier Classification
```tableau
IF [Operating_Hours] > 220 AND [Maintenance_Cost_INR] > 32000 AND [Readiness_Pct] < 60 THEN
    "Tier 1: High Problem Asset"
ELSEIF [Readiness_Pct] < 60 THEN
    "Tier 2: Critical Readiness Deficit"
ELSEIF [Maintenance_Cost_INR] > 38000 THEN
    "Tier 3: Cost Outlier"
ELSE
    "Tier 4: Optimal Fleet Asset"
END
```

### B. Fleet Average Benchmark Reference Lines
```tableau
// Average Operating Hours
WINDOW_AVG(SUM([Operating_Hours]))

// Average Maintenance Cost
WINDOW_AVG(SUM([Maintenance_Cost_INR]))
```

### C. Overdue Maintenance Flag
```tableau
IF [Next_Service] < TODAY() THEN
    "OVERDUE"
ELSEIF [Next_Service] <= DATEADD('day', 14, TODAY()) THEN
    "CRITICAL (Next 14 Days)"
ELSE
    "NORMAL"
END
```

---

## 3. Interactive Tooltips & Dashboard Actions

### Rich Tooltip Specification
Hovering over any asset node renders:
```text
========================================
EQUIPMENT INSPECTOR: <Equipment_ID>
========================================
Base Location    : <Base> (<Region>)
Equipment Type   : <Equipment_Type> (<Category>)
Operational State: <Status>
Readiness Score  : <Readiness_Pct>%
Operating Hours  : <Operating_Hours> hrs (Fleet Avg: 195 hrs)
Maintenance Cost : ₹<Maintenance_Cost_INR> (Fleet Avg: ₹14,700)
Spare Parts      : <Spare_Parts>
Downtime Record  : <Downtime_Days> days
Next Service Due : <Next_Service> (<Overdue Flag>)
========================================
```

### Dashboard Actions:
1. **Filter Action on Base**: Clicking a Base in the Base Readiness Heatmap cross-filters the Scatter Plot to isolate that specific base's assets.
2. **Highlight Action on Spare Parts Shortage**: Hovering over "Critical Shortage" in the legend highlights all affected bubble nodes on the scatter plot.
3. **URL Action / Drill-down**: Clicking a Problem Asset opens the detailed Work Order Maintenance Log history.

---

## 4. Key Analytical Insights Derived

1. **Quadrant 1 (High Problem Assets)** contains **41 units** primarily concentrated in **Kanpur** and **Bhopal**.
2. **Generators** display a distinctive upward curve in Quadrant 2: even at moderate operating hours (~200 hrs), maintenance costs scale exponentially due to component replacements.
3. **Bhopal Tactical Trucks** in the critical readiness zone correlate directly with "Critical Shortage" of starter motors and hydraulic seals.
