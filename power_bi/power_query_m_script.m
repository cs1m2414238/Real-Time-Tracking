// Power BI Power Query M Script: Star Schema Ingestion & Fact Modeling

let
    // 1. Ingest Clean Inventory Data
    Source = Csv.Document(File.Contents("data/fact_equipment_inventory.csv"), [Delimiter=",", Columns=16, Encoding=65001, QuoteStyle=QuoteStyle.None]),
    #"Promoted Headers" = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    #"Changed Type" = Table.TransformColumnTypes(#"Promoted Headers",{
        {"Equipment_ID", type text}, 
        {"Base_ID", type text}, 
        {"Base", type text}, 
        {"Type_ID", type text}, 
        {"Equipment_Type", type text}, 
        {"Category", type text}, 
        {"Status", type text}, 
        {"Last_Service", type date}, 
        {"Next_Service", type date}, 
        {"Fuel_Used_L", Int64.Type}, 
        {"Operating_Hours", Int64.Type}, 
        {"Maintenance_Cost_INR", Currency.Type}, 
        {"Spare_Parts", type text}, 
        {"Readiness_Pct", type number}, 
        {"Downtime_Days", Int64.Type}, 
        {"Is_Critical", Int64.Type}
    }),
    
    // 2. Add Business Columns
    #"Added Service Window" = Table.AddColumn(#"Changed Type", "Service_Window_Bucket", each 
        let 
            DaysUntil = Duration.Days([Next_Service] - #date(2026, 8, 15))
        in 
            if DaysUntil < 0 then "1. Overdue" 
            else if DaysUntil <= 7 then "2. Next 7 Days" 
            else if DaysUntil <= 30 then "3. Next 30 Days" 
            else if DaysUntil <= 60 then "4. Next 60 Days" 
            else "5. >60 Days",
        type text
    ),
    
    #"Added Risk Quadrant" = Table.AddColumn(#"Added Service Window", "Maintenance_Risk_Tier", each
        if [Operating_Hours] > 200 and [Maintenance_Cost_INR] > 30000 and [Readiness_Pct] < 60 then "Tier 1 - High Problem Asset"
        else if [Readiness_Pct] < 60 then "Tier 2 - Low Readiness Risk"
        else if [Maintenance_Cost_INR] > 35000 then "Tier 3 - High Cost Monitoring"
        else "Tier 4 - Standard Operational",
        type text
    )
in
    #"Added Risk Quadrant"
