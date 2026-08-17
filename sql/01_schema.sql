-- ============================================================================
-- MILITARY LOGISTICS & READINESS DATABASE SCHEMA (DDL)
-- Compatible with PostgreSQL 12+, MySQL 8.0+, SQLite 3
-- ============================================================================

-- Drop tables in reverse dependency order if recreating
DROP TABLE IF EXISTS fact_maintenance_logs;
DROP TABLE IF EXISTS fact_equipment_inventory;
DROP TABLE IF EXISTS dim_equipment_types;
DROP TABLE IF EXISTS dim_bases;

-- ----------------------------------------------------------------------------
-- 1. DIMENSION TABLE: Military Bases (dim_bases)
-- ----------------------------------------------------------------------------
CREATE TABLE dim_bases (
    base_id VARCHAR(10) PRIMARY KEY,
    base_name VARCHAR(100) NOT NULL UNIQUE,
    region VARCHAR(100) NOT NULL,
    strategic_role VARCHAR(255) NOT NULL,
    commander_rank VARCHAR(50) NOT NULL,
    target_readiness NUMERIC(5, 2) NOT NULL DEFAULT 85.00
);

-- ----------------------------------------------------------------------------
-- 2. DIMENSION TABLE: Equipment Types (dim_equipment_types)
-- ----------------------------------------------------------------------------
CREATE TABLE dim_equipment_types (
    type_id VARCHAR(10) PRIMARY KEY,
    equipment_type VARCHAR(100) NOT NULL UNIQUE,
    category VARCHAR(100) NOT NULL,
    fuel_burn_rate_l_hr NUMERIC(5, 2) NOT NULL,
    service_interval_days INT NOT NULL,
    base_cost_inr NUMERIC(12, 2) NOT NULL
);

-- ----------------------------------------------------------------------------
-- 3. FACT TABLE: Equipment Fleet Inventory (fact_equipment_inventory)
-- ----------------------------------------------------------------------------
CREATE TABLE fact_equipment_inventory (
    equipment_id VARCHAR(20) PRIMARY KEY,
    base_id VARCHAR(10) NOT NULL REFERENCES dim_bases(base_id),
    base_name VARCHAR(100) NOT NULL,
    type_id VARCHAR(10) NOT NULL REFERENCES dim_equipment_types(type_id),
    equipment_type VARCHAR(100) NOT NULL,
    category VARCHAR(100) NOT NULL,
    status VARCHAR(50) NOT NULL CHECK (status IN ('Operational', 'Maintenance', 'Out of Service')),
    last_service_date DATE NOT NULL,
    next_service_date DATE NOT NULL,
    fuel_used_l INT NOT NULL DEFAULT 0,
    operating_hours INT NOT NULL DEFAULT 0,
    maintenance_cost_inr NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    spare_parts_status VARCHAR(50) NOT NULL CHECK (spare_parts_status IN ('Available', 'Low', 'Critical Shortage')),
    readiness_pct NUMERIC(5, 2) NOT NULL CHECK (readiness_pct >= 0 AND readiness_pct <= 100),
    downtime_days INT NOT NULL DEFAULT 0,
    is_critical INT NOT NULL DEFAULT 0
);

-- ----------------------------------------------------------------------------
-- 4. FACT TABLE: Historical Maintenance Logs (fact_maintenance_logs)
-- ----------------------------------------------------------------------------
CREATE TABLE fact_maintenance_logs (
    log_id VARCHAR(20) PRIMARY KEY,
    equipment_id VARCHAR(20) NOT NULL REFERENCES fact_equipment_inventory(equipment_id) ON DELETE CASCADE,
    base_id VARCHAR(10) NOT NULL REFERENCES dim_bases(base_id),
    service_date DATE NOT NULL,
    service_type VARCHAR(100) NOT NULL,
    technician_rank VARCHAR(50) NOT NULL,
    labor_hours INT NOT NULL,
    parts_replaced TEXT,
    cost_inr NUMERIC(12, 2) NOT NULL,
    downtime_days INT NOT NULL DEFAULT 1
);

-- ----------------------------------------------------------------------------
-- Performance Indexes for Analytics & Fast Joins
-- ----------------------------------------------------------------------------
CREATE INDEX idx_inventory_base ON fact_equipment_inventory(base_id);
CREATE INDEX idx_inventory_type ON fact_equipment_inventory(type_id);
CREATE INDEX idx_inventory_status ON fact_equipment_inventory(status);
CREATE INDEX idx_inventory_readiness ON fact_equipment_inventory(readiness_pct);
CREATE INDEX idx_inventory_next_service ON fact_equipment_inventory(next_service_date);
CREATE INDEX idx_maint_equipment ON fact_maintenance_logs(equipment_id);
CREATE INDEX idx_maint_date ON fact_maintenance_logs(service_date);
