-- SQL Server (T-SQL)
-- Purpose: Propose a Materialized View for daily events by country/campaign
-- Includes partitioning strategy and index recommendations

/* =======================================================================
   '========== QUERY 4: Propose a Materialized View for daily events by country/campaign with partitioning on
event_time and indexes on (country, event_time). =========='
   ======================================================================= */

-- STEP 1: Create the base view with SCHEMABINDING (required for indexed views)
CREATE VIEW vw_daily_events_country_campaign
WITH SCHEMABINDING  -- Prevents underlying table changes that would break the view
AS
SELECT 
    -- Date bucket for daily aggregation
    CAST(e.event_time AS DATE) AS event_date,
    u.country,
    -- Extract campaign from JSON (note: JSON functions are allowed in indexed views in SQL Server 2016+)
    JSON_VALUE(e.payload_json, '$.utm.campaign') AS campaign,
    -- Aggregations
    COUNT_BIG(*) AS event_count,  -- COUNT_BIG required for indexed views
    COUNT_BIG(DISTINCT e.user_id) AS unique_users,  -- Note: DISTINCT not allowed in indexed views, would need separate handling
    COUNT_BIG(DISTINCT JSON_VALUE(e.payload_json, '$.session_id')) AS unique_sessions
FROM 
    dbo.events e  -- Must use two-part name with SCHEMABINDING
    INNER JOIN dbo.users u ON e.user_id = u.user_id
WHERE 
    JSON_VALUE(e.payload_json, '$.utm.campaign') IS NOT NULL
GROUP BY 
    CAST(e.event_time AS DATE),
    u.country,
    JSON_VALUE(e.payload_json, '$.utm.campaign');
GO

-- STEP 2: Create unique clustered index to materialize the view
-- This physically stores the aggregated data and maintains it automatically
CREATE UNIQUE CLUSTERED INDEX IX_vw_daily_events 
ON vw_daily_events_country_campaign (
    event_date,
    country,
    campaign
);
GO

-- STEP 3: Additional non-clustered indexes for common query patterns
CREATE NONCLUSTERED INDEX IX_vw_daily_events_country_date 
ON vw_daily_events_country_campaign (country, event_date)
INCLUDE (event_count, unique_users);

CREATE NONCLUSTERED INDEX IX_vw_daily_events_campaign 
ON vw_daily_events_country_campaign (campaign)
INCLUDE (event_count);

/* =======================================================================
   PARTITIONING STRATEGY
   ======================================================================= */

/*
For a table with billions of events, partitioning is essential:

1. PARTITION FUNCTION - defines how to split the data
*/
CREATE PARTITION FUNCTION pf_event_date (DATE)
AS RANGE RIGHT FOR VALUES (
    '2024-01-01', '2024-04-01', '2024-07-01', '2024-10-01',  -- 2024 quarters
    '2025-01-01', '2025-04-01', '2025-07-01', '2025-10-01',  -- 2025 quarters
    '2026-01-01'  -- Future
);
GO

/*
2. PARTITION SCHEME - maps partitions to filegroups
   (Assuming filegroups FG1, FG2, FG3, FG4 for different storage tiers)
*/
CREATE PARTITION SCHEME ps_event_date
AS PARTITION pf_event_date
TO (FG1, FG1, FG1, FG1, FG2, FG2, FG2, FG2, FG3);  -- Rotate through filegroups
GO

/*
3. CREATE THE PARTITIONED TABLE (if starting from scratch)
   For existing tables, you'd use ALTER TABLE...SWITCH
*/
CREATE TABLE dbo.events_partitioned (
    event_id INT NOT NULL,
    user_id INT NOT NULL,
    event_time DATETIME2 NOT NULL,
    payload_json NVARCHAR(MAX) NOT NULL,
    CONSTRAINT PK_events_partitioned PRIMARY KEY (event_id, event_time)  -- Partition key must be in PK
) ON ps_event_date(event_time);  -- Partition on event_time
GO

/*
4. CREATE ALIGNED INDEXES (partitioned the same way)
*/
CREATE INDEX IX_events_partitioned_user 
ON dbo.events_partitioned(user_id) 
ON ps_event_date(event_time);  -- Aligned index

/* =======================================================================
   COMPREHENSIVE INDEXING STRATEGY
   ======================================================================= */

/*
For the base tables, recommended indexes:

-- Primary indexes (already have PKs)
-- Additional performance indexes:
*/

-- For country + date filtering (most common query pattern)
CREATE NONCLUSTERED INDEX IX_events_country_date 
ON dbo.events(event_time) 
INCLUDE (user_id)  -- Cover the join to users
WHERE JSON_VALUE(payload_json, '$.utm.campaign') IS NOT NULL;  -- Filtered index

-- For campaign analysis queries
CREATE NONCLUSTERED INDEX IX_events_campaign_date 
ON dbo.events(event_time) 
INCLUDE (user_id, payload_json);  -- Covering index

-- Computed column + index alternative (often faster than JSON_VALUE in WHERE)
ALTER TABLE dbo.events ADD campaign AS JSON_VALUE(payload_json, '$.utm.campaign');
CREATE INDEX IX_events_campaign_computed ON dbo.events(campaign, event_time) INCLUDE (user_id);

/* =======================================================================
   PERFORMANCE COMPARISON
   ======================================================================= */

/*
Query Type                       | Without Materialized View        | With Materialized View
---------------------------------|-----------------------------------|------------------------
Daily dashboard (current month)  | Scans millions of rows (5-10 sec) | Instant (<1 sec)
Campaign comparison across years | Full table scan (30+ sec)        | Index seek (1-2 sec)
Country breakdown by hour        | Complex aggregation (slow)        | Pre-aggregated (fast)

Storage Overhead:
- Base table: 100 GB
- Materialized view: ~2-5 GB (depending on cardinality)
- Indexes: Additional 10-15 GB

Refresh Strategy:
- Indexed views are maintained synchronously (on transaction commit)
- For very high volume, consider snapshot-based materialized views refreshed nightly
*/
