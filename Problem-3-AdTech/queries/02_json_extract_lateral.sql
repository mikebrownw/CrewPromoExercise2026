-- SQL Server (T-SQL)
-- Purpose: Extract multiple JSON fields (campaign, source) 
-- Note: SQL Server doesn't have LATERAL parse, so we use multiple JSON_VALUE calls
-- Also demonstrates CROSS APPLY with OPENJSON for more complex parsing

-- METHOD 1: Multiple JSON_VALUE (Simple, good for few fields)
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

-- METHOD 2: OPENJSON with CROSS APPLY (More like LATERAL, better for many fields)
-- This is closer to the "lateral parse" concept mentioned in the question
SELECT 
    e.event_id,
    e.event_time,
    u.country,
    json_values.campaign,
    json_values.source,
    json_values.medium,
    json_values.page,
    json_values.device,
    json_values.session_id
FROM 
    events e
    INNER JOIN users u ON e.user_id = u.user_id
    -- CROSS APPLY acts like a lateral join - evaluates row-by-row
    CROSS APPLY (
        SELECT 
            JSON_VALUE(e.payload_json, '$.utm.campaign') AS campaign,
            JSON_VALUE(e.payload_json, '$.utm.source') AS source,
            JSON_VALUE(e.payload_json, '$.utm.medium') AS medium,
            JSON_VALUE(e.payload_json, '$.page') AS page,
            JSON_VALUE(e.payload_json, '$.device') AS device,
            JSON_VALUE(e.payload_json, '$.session_id') AS session_id
    ) AS json_values
WHERE 
    e.event_time >= '2025-10-01' 
    AND e.event_time < '2026-01-01'
    AND u.country IN ('US', 'CA')
ORDER BY 
    e.event_time;

-- METHOD 3: OPENJSON with explicit schema (Most powerful for complex JSON)
-- Useful when JSON structure varies or has nested arrays
SELECT 
    e.event_id,
    e.event_time,
    u.country,
    utm.campaign,
    utm.source,
    utm.medium,
    page_data.page,
    page_data.device,
    page_data.session_id
FROM 
    events e
    INNER JOIN users u ON e.user_id = u.user_id
    -- Parse the entire utm object
    CROSS APPLY OPENJSON(e.payload_json, '$.utm') WITH (
        campaign VARCHAR(50) '$.campaign',
        source VARCHAR(50) '$.source',
        medium VARCHAR(50) '$.medium'
    ) AS utm
    -- Parse top-level fields
    CROSS APPLY (
        SELECT 
            JSON_VALUE(e.payload_json, '$.page') AS page,
            JSON_VALUE(e.payload_json, '$.device') AS device,
            JSON_VALUE(e.payload_json, '$.session_id') AS session_id
    ) AS page_data
WHERE 
    e.event_time >= '2025-10-01' 
    AND e.event_time < '2026-01-01'
    AND u.country IN ('US', 'CA');

/* Explanation:
   - SQL Server doesn't have native LATERAL keyword like PostgreSQL
   - CROSS APPLY is the equivalent - it applies a table-valued function to each row
   - OPENJSON with WITH clause provides strongly-typed JSON parsing
   - This approach is more maintainable when extracting many fields
*/
