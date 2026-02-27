-- Test queries for Problem 3 (AdTech)

/* =======================================================================
   TESTING SOLUTION FOR PROBLEM 3
   ======================================================================= */

-- Test 1: Verify Q4 2025 date range
PRINT 'Test 1: Verify Q4 2025 date range';
SELECT 
    MIN(event_time) AS q4_start,
    MAX(event_time) AS q4_end,
    COUNT(*) AS total_events_in_q4
FROM events
WHERE event_time >= '2025-10-01' AND event_time < '2026-01-01';
-- Expected: Dates between Oct 1 - Dec 31, 2025

-- Test 2: Verify US and CA events only
PRINT 'Test 2: Verify country filter';
SELECT 
    u.country,
    COUNT(*) AS event_count
FROM events e
JOIN users u ON e.user_id = u.user_id
WHERE e.event_time >= '2025-10-01' AND e.event_time < '2026-01-01'
GROUP BY u.country;
-- Expected: Only US and CA should appear (others filtered out)

-- Test 3: Verify JSON extraction works
PRINT 'Test 3: Verify JSON extraction';
SELECT TOP 5
    event_id,
    JSON_VALUE(payload_json, '$.utm.campaign') AS campaign,
    JSON_VALUE(payload_json, '$.utm.source') AS source,
    payload_json AS raw_json
FROM events
WHERE JSON_VALUE(payload_json, '$.utm.campaign') IS NOT NULL;
-- Expected: Campaign values like 'black_friday', 'fall_sale', etc.

-- Test 4: Test Question 1 - Count by campaign
PRINT 'Test 4: Question 1 - Events by campaign';
SELECT 
    JSON_VALUE(e.payload_json, '$.utm.campaign') AS campaign,
    u.country,
    COUNT(*) AS event_count
FROM events e
JOIN users u ON e.user_id = u.user_id
WHERE e.event_time >= '2025-10-01' AND e.event_time < '2026-01-01'
    AND u.country IN ('US', 'CA')
    AND JSON_VALUE(e.payload_json, '$.utm.campaign') IS NOT NULL
GROUP BY JSON_VALUE(e.payload_json, '$.utm.campaign'), u.country
ORDER BY u.country, event_count DESC;
-- Expected: 'black_friday' should be top in US

-- Test 5: Test Question 3 - Top campaign per country
PRINT 'Test 5: Question 3 - Top campaign per country';
WITH campaign_stats AS (
    SELECT 
        u.country,
        JSON_VALUE(e.payload_json, '$.utm.campaign') AS campaign,
        COUNT(*) AS event_count
    FROM events e
    JOIN users u ON e.user_id = u.user_id
    WHERE e.event_time >= '2025-10-01' AND e.event_time < '2026-01-01'
        AND u.country IN ('US', 'CA')
        AND JSON_VALUE(e.payload_json, '$.utm.campaign') IS NOT NULL
    GROUP BY u.country, JSON_VALUE(e.payload_json, '$.utm.campaign')
),
ranked AS (
    SELECT 
        country,
        campaign,
        event_count,
        ROW_NUMBER() OVER (PARTITION BY country ORDER BY event_count DESC) AS rn
    FROM campaign_stats
)
SELECT country, campaign, event_count
FROM ranked
WHERE rn = 1
ORDER BY country;
-- Expected: US: 'black_friday', CA: (depends on data distribution)

PRINT 'All tests completed';
