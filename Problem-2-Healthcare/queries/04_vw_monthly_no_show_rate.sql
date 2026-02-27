-- SQL Server (T-SQL)
-- Purpose: Create view for monthly no-show rate analysis
-- Includes discussion of indexes and partitioning

CREATE OR ALTER VIEW vw_monthly_no_show_rate
AS
WITH monthly_stats AS (
    SELECT 
        YEAR(appt_date) AS year,
        MONTH(appt_date) AS month,
        DATENAME(month, appt_date) AS month_name,
        region,
        COUNT(*) AS total_appointments,
        SUM(CASE WHEN status = 'NO_SHOW' THEN 1 ELSE 0 END) AS no_show_count,
        SUM(CASE WHEN status = 'COMPLETED' THEN 1 ELSE 0 END) AS completed_count,
        COUNT(DISTINCT patient_id) AS unique_patients
    FROM 
        appointments a
        INNER JOIN patients p ON a.patient_id = p.patient_id
    WHERE 
        status IN ('COMPLETED', 'NO_SHOW')  -- Exclude future SCHEDULED
    GROUP BY 
        YEAR(appt_date),
        MONTH(appt_date),
        DATENAME(month, appt_date),
        region
)
SELECT 
    year,
    month,
    month_name,
    region,
    total_appointments,
    no_show_count,
    completed_count,
    -- Calculate no-show rate with proper decimal handling
    CAST(
        CASE 
            WHEN total_appointments > 0 
            THEN (no_show_count * 100.0) / total_appointments
            ELSE 0 
        END AS DECIMAL(5,2)
    ) AS no_show_rate_percent,
    unique_patients,
    -- Calculate rolling 3-month average for trend analysis
    AVG(CASE 
            WHEN total_appointments > 0 
            THEN (no_show_count * 100.0) / total_appointments
            ELSE 0 
        END) OVER (
            PARTITION BY region 
            ORDER BY year, month 
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS rolling_3month_avg_rate
FROM 
    monthly_stats
GO

-- Grant select permissions (adjust as needed)
-- GRANT SELECT ON vw_monthly_no_show_rate TO ANALYST_ROLE;

------------------------------------------------------------------------
-- Alternative CTE (Common Table Expression), for when unable to test view ^
SELECT 
    a.appt_id,
    a.appt_date,
    a.status,
    p.patient_id,
    p.name AS patient_name,
    p.region,
    'Northeast' AS test_region,  -- Change this to test
    '2025-07-01' AS test_from,
    '2025-12-31' AS test_to
INTO #test_results
FROM appointments a
INNER JOIN patients p ON a.patient_id = p.patient_id
WHERE 1=0;  -- Create empty structure

-- Then query with your test parameters
INSERT INTO #test_results
SELECT 
    a.appt_id,
    a.appt_date,
    a.status,
    p.patient_id,
    p.name,
    p.region,
    'Northeast' AS test_region,
    '2025-07-01' AS test_from,
    '2025-12-31' AS test_to
FROM appointments a
INNER JOIN patients p ON a.patient_id = p.patient_id
WHERE 
    a.appt_date BETWEEN '2025-07-01' AND '2025-12-31'
    AND a.status = 'SCHEDULED'
    AND p.region = 'Northeast';

-- View results
SELECT * FROM #test_results;

/* =======================================================================
   PERFORMANCE OPTIMIZATION DISCUSSION
   ======================================================================= */

/* 
1. RECOMMENDED INDEXES:
   ---------------------
   a) Composite index for patient history lookups:
      CREATE INDEX idx_appointments_patient_date ON appointments(patient_id, appt_date) INCLUDE (status);
      - Supports WHERE patient_id = ? queries
      - INCLUDE clause covers status without increasing index size much
      - Crucial for patient-level analysis
   
   b) Date-range index for time-based aggregations:
      CREATE INDEX idx_appointments_date_status ON appointments(appt_date, status) INCLUDE (patient_id);
      - Supports WHERE appt_date BETWEEN ? AND ? queries
      - Essential for monthly/yearly reporting
      - SARGable: column isn't wrapped in functions
   
   c) Covering index for the view query:
      CREATE INDEX idx_appointments_all ON appointments(appt_date, status, patient_id);
      - Would make this view completely indexed (no table access needed)

2. PARTITIONING STRATEGY:
   ----------------------
   For tables with millions of rows, partition by appt_date:
   
   -- Create partition function (by year or quarter)
   CREATE PARTITION FUNCTION pf_appt_date (DATE)
   AS RANGE RIGHT FOR VALUES (
       '2020-01-01', '2021-01-01', '2022-01-01', 
       '2023-01-01', '2024-01-01', '2025-01-01'
   );
   
   -- Create partition scheme
   CREATE PARTITION SCHEME ps_appt_date
   AS PARTITION pf_appt_date TO (FG1, FG2, FG3, FG4, FG5, FG6, FG7);
   
   -- Create partitioned table
   CREATE TABLE appointments_partitioned (
       appt_id INT NOT NULL,
       patient_id INT NOT NULL,
       appt_date DATE NOT NULL,
       status VARCHAR(20)
   ) ON ps_appt_date(appt_date);
   
   Benefits of partitioning by appt_date:
   - Partition elimination: queries only scan relevant year(s)
   - Easier data archival (DROP PARTITION vs DELETE)
   - Parallel partition scanning for aggregations
   - Improved maintenance windows

3. MATERIALIZED VIEW ALTERNATIVE:
   ------------------------------
   For enterprise workloads, consider indexed view:
   
   CREATE VIEW vw_monthly_no_show_materialized
   WITH SCHEMABINDING
   AS
   SELECT 
       YEAR(appt_date) AS year,
       MONTH(appt_date) AS month,
       region,
       COUNT_BIG(*) AS total_appts,
       SUM(CASE WHEN status = 'NO_SHOW' THEN 1 ELSE 0 END) AS no_shows
   FROM dbo.appointments a
   JOIN dbo.patients p ON a.patient_id = p.patient_id
   GROUP BY YEAR(appt_date), MONTH(appt_date), region;
   
   -- Create unique clustered index to materialize
   CREATE UNIQUE CLUSTERED INDEX IX_monthly_no_show 
   ON vw_monthly_no_show_materialized (year, month, region);
   
   This would make monthly reporting instantaneous.
*/
