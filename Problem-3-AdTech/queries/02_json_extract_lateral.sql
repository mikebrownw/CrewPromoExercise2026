-- SQL Server (T-SQL)
-- Purpose: Extract multiple JSON fields (campaign, source) 
-- Note: SQL Server doesn't have LATERAL parse, so we use multiple JSON_VALUE calls

PRINT '========== QUERY 2: Extract multiple JSON fields (campaign, source) via a lateral parse if engine supports it (or
repeat JSON_VALUE). ==========';

--Multiple JSON_VALUE
SELECT 
    e.event_id,
    e.event_time,
    u.country,
    -- Extract multiple fields using JSON_VALUE
    JSON_VALUE(e.payload_json, '$.utm.campaign') AS campaign,
    JSON_VALUE(e.payload_json, '$.utm.source') AS source,
    JSON_VALUE(e.payload_json, '$.utm.medium') AS medium,
    JSON_VALUE(e.payload_json, '$.page') AS page,
    JSON_VALUE(e.payload_json, '$.device') AS device,
    JSON_VALUE(e.payload_json, '$.session_id') AS session_id
FROM 
    events e
    INNER JOIN users u ON e.user_id = u.user_id
WHERE 
    e.event_time >= '2025-10-01' 
    AND e.event_time < '2026-01-01'
    AND u.country IN ('US', 'CA')
ORDER BY 
    e.event_time;
