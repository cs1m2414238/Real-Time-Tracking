# Microsoft Excel: Power Query ETL Transformation Guide

## Overview

This guide provides the exact **Power Query (M Language)** transformation pipeline used to ingest dirty military equipment logistics logs, perform data hygiene and type enforcement, validate referential integrity, and load clean data into the reporting model.

---

## 1. Problem Statement: Dirty Logistics Raw Records

The raw dataset (`raw_equipment_dirty.csv`) simulates messy field-generated data with the following common real-world defects:
- **Inconsistent Casing & Trailing Whitespace**: `lucknow`, `LUCKNOW`, `  bhopal `, `kANPUR`.
- **Text & Currency Formatting Inconsistencies**: `₹12,000`, `12,000 INR`, `Rs. 12000`, and missing numbers.
- **Malformed Dates**: Mixed date string formats (`DD-Mon-YYYY`, `YYYY/MM/DD`, `DD/MM/YYYY`, `MM-DD-YYYY`).
- **Inconsistent Status & Category Labels**: `OPERATIONAL`, `operational`, `Under Maint.`, `Maint`, `apc`.
- **Readiness Value Discrepancies**: Decimal values (`0.92`), percentages (`92%`), and whole numbers (`92`).
- **Duplicate Equipment IDs**: Duplicate records injected due to multi-source batch sync errors.
- **Null / Empty Fields**: Missing fuel consumption, spare parts status, or operating hours.

---

## 2. Power Query M Script

Below is the complete M code. In Excel or Power BI:
1. Go to **Data > Get Data > From Other Sources > Blank Query**.
2. Open **Advanced Editor** and paste the code below:

```powerquery
let
    // Step 1: Ingest raw dirty CSV file
    Source = Csv.Document(
        File.Contents("data\raw_equipment_dirty.csv"),
        [Delimiter=",", Columns=11, Encoding=65001, QuoteStyle=QuoteStyle.None]
    ),
    #"Promoted Headers" = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),

    // Step 2: Deduplicate records based on Equipment_ID
    #"Removed Duplicates" = Table.Distinct(#"Promoted Headers", {"Equipment_ID"}),

    // Step 3: Clean & Standardize Base names (Trim whitespace + Proper Casing)
    #"Trimmed Base" = Table.TransformColumns(#"Removed Duplicates", {{"Base", Text.Trim, type text}}),
    #"Cleaned Base Casing" = Table.TransformColumns(#"Trimmed Base", {{"Base", Text.Proper, type text}}),

    // Step 4: Clean & Standardize Equipment Type names
    #"Trimmed Equipment Type" = Table.TransformColumns(#"Cleaned Base Casing", {{"Equipment_Type", Text.Trim, type text}}),
    #"Cleaned Equipment Type Casing" = Table.TransformColumns(#"Trimmed Equipment Type", {{"Equipment_Type", Text.Proper, type text}}),
    #"Replaced UnderScore Types" = Table.ReplaceValue(#"Cleaned Equipment Type Casing", "_", " ", Replacer.ReplaceText, {"Equipment_Type"}),

    // Step 5: Clean Status column
    #"Trimmed Status" = Table.TransformColumns(#"Replaced UnderScore Types", {{"Status", Text.Trim, type text}}),
    #"Cleaned Status Casing" = Table.TransformColumns(#"Trimmed Status", {{"Status", Text.Proper, type text}}),
    #"Standardized Status" = Table.ReplaceValue(#"Cleaned Status Casing", "Maint", "Maintenance", Replacer.ReplaceText, {"Status"}),

    // Step 6: Parse & Clean Currency in Maintenance Cost (Remove ₹, INR, Rs., commas)
    #"Replaced Rupee Symbol" = Table.ReplaceValue(#"Standardized Status", "₹", "", Replacer.ReplaceText, {"Maintenance_Cost"}),
    #"Replaced INR Text" = Table.ReplaceValue(#"Replaced Rupee Symbol", "INR", "", Replacer.ReplaceText, {"Maintenance_Cost"}),
    #"Replaced Rs Text" = Table.ReplaceValue(#"Replaced INR Text", "Rs.", "", Replacer.ReplaceText, {"Maintenance_Cost"}),
    #"Replaced Commas Cost" = Table.ReplaceValue(#"Replaced Rs Text", ",", "", Replacer.ReplaceText, {"Maintenance_Cost"}),
    #"Trimmed Cost" = Table.TransformColumns(#"Replaced Commas Cost", {{"Maintenance_Cost", Text.Trim, type text}}),

    // Step 7: Clean Readiness Column (Handle percentages, decimals, and numbers)
    #"Replaced Pct Symbol" = Table.ReplaceValue(#"Trimmed Cost", "%", "", Replacer.ReplaceText, {"Readiness"}),
    #"Trimmed Readiness" = Table.TransformColumns(#"Replaced Pct Symbol", {{"Readiness", Text.Trim, type text}}),
    #"Converted Readiness Number" = Table.TransformColumns(#"Trimmed Readiness", {{"Readiness", each try Value.FromText(_) otherwise null, type number}}),
    #"Normalized Readiness Scale" = Table.TransformColumns(#"Converted Readiness Number", {
        {"Readiness", each if _ <> null and _ <= 1.0 then _ * 100.0 else _, type number}
    }),

    // Step 8: Parse Dates with multi-format fallback
    #"Parsed Last Service" = Table.TransformColumns(#"Normalized Readiness Scale", {
        {"Last_Service", each try Date.FromText(_, "en-US") otherwise try Date.FromText(_, "en-GB") otherwise null, type date}
    }),
    #"Parsed Next Service" = Table.TransformColumns(#"Parsed Last Service", {
        {"Next_Service", each try Date.FromText(_, "en-US") otherwise try Date.FromText(_, "en-GB") otherwise null, type date}
    }),

    // Step 9: Handle Nulls & Impute Defaults
    #"Imputed Spare Parts" = Table.ReplaceValue(#"Parsed Next Service", null, "Available", Replacer.ReplaceValue, {"Spare_Parts"}),
    #"Imputed Fuel Used" = Table.ReplaceValue(#"Imputed Spare Parts", null, "0", Replacer.ReplaceValue, {"Fuel_Used"}),

    // Step 10: Strict Data Type Enforcement
    #"Changed Final Types" = Table.TransformColumnTypes(#"Imputed Fuel Used", {
        {"Equipment_ID", type text},
        {"Base", type text},
        {"Equipment_Type", type text},
        {"Status", type text},
        {"Last_Service", type date},
        {"Next_Service", type date},
        {"Fuel_Used", Int64.Type},
        {"Operating_Hours", Int64.Type},
        {"Maintenance_Cost", Currency.Type},
        {"Spare_Parts", type text},
        {"Readiness", type number}
    }),

    // Step 11: Add Custom Business Columns
    #"Added Critical Asset Flag" = Table.AddColumn(#"Changed Final Types", "Is_Critical", each if [Readiness] < 60.0 then 1 else 0, Int64.Type),
    #"Added Service Window Category" = Table.AddColumn(#"Added Critical Asset Flag", "Service_Urgency", each 
        let 
            DaysUntilService = Duration.Days([Next_Service] - DateTime.Date(DateTime.LocalNow()))
        in
            if DaysUntilService < 0 then "Overdue"
            else if DaysUntilService <= 7 then "Urgent (0-7 Days)"
            else if DaysUntilService <= 30 then "Planned (8-30 Days)"
            else "Routine (>30 Days)",
        type text
    )
in
    #"Added Service Window Category"
```

---

## 3. Interview Talking Points

> **Interview Answer:**
> *"When ingesting field logistics logs, raw operational records often contain casing discrepancies (e.g., lowercase vs. uppercase base names), duplicate equipment IDs from concurrent syncs, mixed currency strings, and varying date formats.
>
> In Power Query, I established an automated M ETL pipeline that deduplicated records on `Equipment_ID`, cleaned strings using `Text.Trim` and `Text.Proper`, stripped currency symbols, normalized readiness rates to a consistent 0–100% scale, and applied multi-locale date parsing. Finally, I added conditional business columns such as `Is_Critical` (<60% readiness) and `Service_Urgency` before loading the transformed dataset into the Power BI star-schema model."*
