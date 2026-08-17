-- ============================================================================
-- MILITARY LOGISTICS & READINESS ANALYTICAL SQL QUERIES
-- Demonstrating: GROUP BY, CASE WHEN, Multi-Table JOINs, CTEs, Window Functions
-- ============================================================================

-- ----------------------------------------------------------------------------
-- QUERY 1: Base-Level Fleet Size, Operational Breakdown & Readiness Rate
-- Focus: Aggregate KPI computation with conditional CASE WHEN aggregation
-- ----------------------------------------------------------------------------
SELECT 
    b.base_name,
    b.region,
    b.target_readiness,
    COUNT(e.equipment_id) AS total_fleet_size,
    SUM(CASE WHEN e.status = 'Operational' THEN 1 ELSE 0 END) AS operational_count,
    SUM(CASE WHEN e.status = 'Maintenance' THEN 1 ELSE 0 END) AS maintenance_count,
    SUM(CASE WHEN e.status = 'Out of Service' THEN 1 ELSE 0 END) AS out_of_service_count,
    ROUND(
        (SUM(CASE WHEN e.status = 'Operational' THEN 1.0 ELSE 0.0 END) / COUNT(e.equipment_id)) * 100.0, 
        2
    ) AS actual_readiness_pct,
    ROUND(
        ROUND((SUM(CASE WHEN e.status = 'Operational' THEN 1.0 ELSE 0.0 END) / COUNT(e.equipment_id)) * 100.0, 2) - b.target_readiness,
        2
    ) AS readiness_variance_vs_target
FROM fact_equipment_inventory e
JOIN dim_bases b ON e.base_id = b.base_id
GROUP BY b.base_name, b.region, b.target_readiness
ORDER BY actual_readiness_pct DESC;


-- ----------------------------------------------------------------------------
-- QUERY 2: Equipment Category Cost & Utilization Efficiency
-- Focus: Aggregations, Average operating hours vs. maintenance expense
-- ----------------------------------------------------------------------------
SELECT 
    t.equipment_type,
    t.category,
    COUNT(e.equipment_id) AS total_units,
    ROUND(AVG(e.operating_hours), 1) AS avg_operating_hours,
    ROUND(AVG(e.maintenance_cost_inr), 2) AS avg_maintenance_cost,
    ROUND(AVG(e.fuel_used_l), 1) AS avg_fuel_consumed_l,
    ROUND(
        AVG(e.maintenance_cost_inr) / NULLIF(AVG(e.operating_hours), 0), 
        2
    ) AS cost_per_operating_hour
FROM fact_equipment_inventory e
JOIN dim_equipment_types t ON e.type_id = t.type_id
GROUP BY t.equipment_type, t.category
ORDER BY avg_maintenance_cost DESC;


-- ----------------------------------------------------------------------------
-- QUERY 3: CTE - High-Risk Problem Asset Identification
-- Focus: Multi-CTE pipeline filtering High Operating Hours + High Cost + Low Readiness
-- ----------------------------------------------------------------------------
WITH FleetBenchmarks AS (
    SELECT 
        AVG(operating_hours) AS fleet_avg_hours,
        AVG(maintenance_cost_inr) AS fleet_avg_cost
    FROM fact_equipment_inventory
),
HighRiskAssets AS (
    SELECT 
        e.equipment_id,
        e.base_name,
        e.equipment_type,
        e.operating_hours,
        e.maintenance_cost_inr,
        e.readiness_pct,
        e.spare_parts_status,
        e.status,
        b.fleet_avg_hours,
        b.fleet_avg_cost
    FROM fact_equipment_inventory e
    CROSS JOIN FleetBenchmarks b
    WHERE e.operating_hours > b.fleet_avg_hours
      AND e.maintenance_cost_inr > b.fleet_avg_cost
      AND e.readiness_pct < 65.0
)
SELECT 
    equipment_id,
    base_name,
    equipment_type,
    operating_hours,
    maintenance_cost_inr,
    readiness_pct,
    spare_parts_status,
    status
FROM HighRiskAssets
ORDER BY readiness_pct ASC, maintenance_cost_inr DESC;


-- ----------------------------------------------------------------------------
-- QUERY 4: Window Functions - Base-Wise Asset Readiness Ranking
-- Focus: ROW_NUMBER(), DENSE_RANK() partitioned by Base to identify worst 3 assets per base
-- ----------------------------------------------------------------------------
WITH RankedAssets AS (
    SELECT 
        equipment_id,
        base_name,
        equipment_type,
        status,
        readiness_pct,
        downtime_days,
        maintenance_cost_inr,
        ROW_NUMBER() OVER (
            PARTITION BY base_name 
            ORDER BY readiness_pct ASC, downtime_days DESC
        ) AS rank_within_base
    FROM fact_equipment_inventory
)
SELECT 
    base_name,
    rank_within_base AS priority_rank,
    equipment_id,
    equipment_type,
    status,
    readiness_pct,
    downtime_days,
    maintenance_cost_inr
FROM RankedAssets
WHERE rank_within_base <= 3
ORDER BY base_name, priority_rank;


-- ----------------------------------------------------------------------------
-- QUERY 5: Upcoming Service Timeline & Overdue Maintenance Windows
-- Focus: Date calculations and triage urgency categories
-- ----------------------------------------------------------------------------
SELECT 
    CASE 
        WHEN next_service_date < '2026-08-15' THEN '1. Overdue Service'
        WHEN next_service_date <= '2026-08-22' THEN '2. Urgent (Next 7 Days)'
        WHEN next_service_date <= '2026-09-14' THEN '3. Near-Term (Next 30 Days)'
        WHEN next_service_date <= '2026-10-14' THEN '4. Medium-Term (Next 60 Days)'
        ELSE '5. Routine (>60 Days)'
    END AS service_window_category,
    COUNT(*) AS equipment_count,
    SUM(CASE WHEN status = 'Operational' THEN 1 ELSE 0 END) AS currently_operational,
    SUM(CASE WHEN spare_parts_status = 'Critical Shortage' THEN 1 ELSE 0 END) AS parts_at_risk,
    SUM(maintenance_cost_inr) AS estimated_maint_cost_inr
FROM fact_equipment_inventory
GROUP BY 
    CASE 
        WHEN next_service_date < '2026-08-15' THEN '1. Overdue Service'
        WHEN next_service_date <= '2026-08-22' THEN '2. Urgent (Next 7 Days)'
        WHEN next_service_date <= '2026-09-14' THEN '3. Near-Term (Next 30 Days)'
        WHEN next_service_date <= '2026-10-14' THEN '4. Medium-Term (Next 60 Days)'
        ELSE '5. Routine (>60 Days)'
    END
ORDER BY service_window_category;


-- ----------------------------------------------------------------------------
-- QUERY 6: Spare Parts Availability Impact on Operational Downtime
-- Focus: Correlating supply chain bottlenecks with equipment downtime days
-- ----------------------------------------------------------------------------
SELECT 
    spare_parts_status,
    COUNT(*) AS asset_count,
    ROUND(AVG(readiness_pct), 2) AS avg_readiness_pct,
    ROUND(AVG(downtime_days), 1) AS avg_downtime_days,
    SUM(CASE WHEN status = 'Out of Service' THEN 1 ELSE 0 END) AS out_of_service_count,
    ROUND(SUM(maintenance_cost_inr), 2) AS total_maintenance_cost
FROM fact_equipment_inventory
GROUP BY spare_parts_status
ORDER BY avg_downtime_days DESC;


-- ----------------------------------------------------------------------------
-- QUERY 7: Window Function - Historical Service Frequency & Cost Trend
-- Focus: CTE + LAG() to measure cost progression across maintenance events
-- ----------------------------------------------------------------------------
WITH MaintenanceHistory AS (
    SELECT 
        log_id,
        equipment_id,
        service_date,
        cost_inr,
        downtime_days,
        LAG(cost_inr, 1) OVER (
            PARTITION BY equipment_id 
            ORDER BY service_date ASC
        ) AS previous_service_cost,
        LAG(service_date, 1) OVER (
            PARTITION BY equipment_id 
            ORDER BY service_date ASC
        ) AS previous_service_date
    FROM fact_maintenance_logs
)
SELECT 
    log_id,
    equipment_id,
    service_date,
    previous_service_date,
    cost_inr AS current_cost,
    previous_service_cost,
    (cost_inr - previous_service_cost) AS cost_increase_inr
FROM MaintenanceHistory
WHERE previous_service_cost IS NOT NULL
ORDER BY cost_increase_inr DESC
LIMIT 20;
