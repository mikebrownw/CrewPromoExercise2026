-- SQL Server (T-SQL)
-- Purpose: Count events by utm.campaign for US and CA in Q4 2025
-- Demonstrates JSON_VALUE for JSON field extraction

SELECT 
    -- Extract campaign from JSON payload
    JSON_VALUE(e.payload_json, '$.utm.campaign') AS campaign,
    u.country,
    COUNT(*) AS event_count,
    -- Additional metrics for context
    COUNT(DISTINCT e.user_id) AS unique_users,
    COUNT(DISTINCT JSON_VALUE(e.payload_json, '$.session_id')) AS unique_sessions,
    MIN(e.event_time) AS first_event,
    MAX(e.event_time) AS last_event
FROM 
    events e
    INNER JOIN users u ON e.user_id = u.user_id
WHERE 
    -- Q4 2025 filter (SARGable: no function on column)
    e.event_time >= '2025-10-01' 
    AND e.event_time < '2026-01-01'
    -- US and Canada only
    AND u.country IN ('US', 'CA')
    -- Ensure campaign exists in JSON (avoid NULLs)
    AND JSON_VALUE(e.payload_json, '$.utm.campaign') IS NOT NULL
GROUP BY 
    JSON_VALUE(e.payload_json, '$.utm.campaign'),
    u.country
ORDER BY 
    u.country,
    event_count DESC;

/* Expected Results:
   - Should show campaigns like 'black_friday', 'fall_sale', 'cyber_monday', 'holiday_sale'
   - US likely has more events than CA based on sample data
   - 'black_friday' should be top campaign in US
*/
