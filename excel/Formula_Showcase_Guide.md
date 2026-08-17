# Microsoft Excel: Advanced Formulas & Dynamic Arrays Showcase

## Overview

This guide details the exact Excel formulas implemented in [`military_logistics_model.xlsx`](file:///c:/Users/Priyanshu%20Sharma/Desktop/new2/data/military_logistics_model.xlsx) to demonstrate core analytical capabilities: `XLOOKUP`, `INDEX-MATCH`, `SUMIFS`, `COUNTIFS`, `AVERAGEIFS`, and Modern Dynamic Arrays (`FILTER`, `UNIQUE`, `SORT`).

---

## 1. Single Asset Lookup Engine (`XLOOKUP` vs `INDEX-MATCH`)

When evaluating or auditing an individual equipment asset (e.g. Cell `B5 = "EQ-1003"`), formulas retrieve attributes dynamically from the master inventory tab (`Cleaned_Inventory`).

### A. Modern `XLOOKUP` Implementation
```excel
// Base Name Lookup
=XLOOKUP(B5, Cleaned_Inventory!A2:A1251, Cleaned_Inventory!C2:C1251, "Not Found")

// Equipment Type Lookup
=XLOOKUP(B5, Cleaned_Inventory!A2:A1251, Cleaned_Inventory!E2:E1251, "Not Found")

// Maintenance Cost Lookup with default 0 if missing
=XLOOKUP(B5, Cleaned_Inventory!A2:A1251, Cleaned_Inventory!L2:L1251, 0)

// Operating Hours Lookup
=XLOOKUP(B5, Cleaned_Inventory!A2:A1251, Cleaned_Inventory!K2:K1251, 0)
```

### B. Robust Classic `INDEX-MATCH` Implementation
Used for backward compatibility and two-way dynamic matrix lookups:
```excel
// Operational Status
=INDEX(Cleaned_Inventory!G2:G1251, MATCH(B5, Cleaned_Inventory!A2:A1251, 0))

// Readiness Score %
=INDEX(Cleaned_Inventory!N2:N1251, MATCH(B5, Cleaned_Inventory!A2:A1251, 0))

// Spare Parts Availability Status
=INDEX(Cleaned_Inventory!M2:M1251, MATCH(B5, Cleaned_Inventory!A2:A1251, 0))
```

---

## 2. Multi-Condition Aggregations (`SUMIFS`, `COUNTIFS`, `AVERAGEIFS`)

Used to populate the Executive KPI Matrix across military bases:

### A. Total Assets Per Base
```excel
=COUNTIF(Cleaned_Inventory!$C$2:$C$1251, "Lucknow")
```

### B. Operational Assets Per Base (Multi-criteria)
```excel
=COUNTIFS(Cleaned_Inventory!$C$2:$C$1251, "Lucknow", Cleaned_Inventory!$G$2:$G$1251, "Operational")
```

### C. Base Readiness Rate %
```excel
=COUNTIFS(Cleaned_Inventory!$C$2:$C$1251, "Lucknow", Cleaned_Inventory!$G$2:$G$1251, "Operational") / COUNTIF(Cleaned_Inventory!$C$2:$C$1251, "Lucknow")
```

### D. Total Maintenance Expenditure Per Base
```excel
=SUMIF(Cleaned_Inventory!$C$2:$C$1251, "Lucknow", Cleaned_Inventory!$L$2:$L$1251)
```

### E. Average Downtime Days for Vehicles Under Maintenance in Kanpur
```excel
=AVERAGEIFS(Cleaned_Inventory!$O$2:$O$1251, Cleaned_Inventory!$C$2:$C$1251, "Kanpur", Cleaned_Inventory!$G$2:$G$1251, "Maintenance")
```

---

## 3. Dynamic Array Formulas (Excel 365 / 2021+)

Modern formula features that spill results dynamically:

### A. Distinct List of Operational Bases
```excel
=SORT(UNIQUE(Cleaned_Inventory!C2:C1251))
```

### B. Sorted Distinct Equipment Categories
```excel
=SORT(UNIQUE(Cleaned_Inventory!F2:F1251))
```

### C. Dynamic Filter for Critical Assets (Readiness < 60%)
```excel
=FILTER(
    Cleaned_Inventory!A2:N1251,
    Cleaned_Inventory!P2:P1251 = 1,
    "No Critical Assets Found"
)
```

### D. Multi-Condition Dynamic Filter (Kanpur + Under Maintenance)
```excel
=FILTER(
    Cleaned_Inventory!A2:L1251,
    (Cleaned_Inventory!C2:C1251 = "Kanpur") * (Cleaned_Inventory!G2:G1251 = "Maintenance"),
    "No Assets Under Maintenance in Kanpur"
)
```

---

## 4. Pivot Table Construction Guide

To replicate the summary matrix in Excel:
1. **Source Range**: `Cleaned_Inventory!$A$1:$P$1251`
2. **Rows**: `Base` -> `Equipment_Type`
3. **Columns**: `Status` (Operational, Maintenance, Out of Service)
4. **Values**:
   - `Count of Equipment_ID` (Fleet Count)
   - `Sum of Maintenance_Cost_INR` (Formatted as Currency `₹#,##0`)
   - `Average of Readiness_Pct` (Formatted as `0.0%`)
5. **Filters / Slicers**:
   - `Spare_Parts` (Available, Low, Critical Shortage)
   - `Category` (Transport, Armor, Power Logistics, Surveillance)
