-- SQL Server (T-SQL)
-- Purpose: Return the top campaign by events per country in Q4 2025
-- Uses window functions with ranking

WITH campaign_stats AS (
    -- First, aggregate events by country and campaign
    SELECT 
        u.country,
        JSON_VALUE(e.payload_json, '$.utm.campaign') AS campaign,
        COUNT(*) AS event_count,
        COUNT(DISTINCT e.user_id) AS unique_users,
        COUNT(DISTINCT JSON_VALUE(e.payload_json, '$.session_id')) AS sessions
    FROM 
        events e
        INNER JOIN users u ON e.user_id = u.user_id
    WHERE 
        e.event_time >= '2025-10-01' 
        AND e.event_time < '2026-01-01'
        AND u.country IN ('US', 'CA')
        AND JSON_VALUE(e.payload_json, '$.utm.campaign') IS NOT NULL
    GROUP BY 
        u.country,
        JSON_VALUE(e.payload_json, '$.utm.campaign')
),
ranked_campaigns AS (
    -- Rank campaigns within each country
    SELECT 
        country,
        campaign,
        event_count,
        unique_users,
        sessions,
        -- Calculate percentage of total events in country
        CAST(event_count * 100.0 / SUM(event_count) OVER (PARTITION BY country) AS DECIMAL(5,2)) AS pct_of_country_events,
        -- Rank by event count (use DENSE_RANK to handle ties)
        DENSE_RANK() OVER (
            PARTITION BY country 
            ORDER BY event_count DESC
        ) AS rank_num
    FROM 
        campaign_stats
)
-- Return top campaign per country (rank = 1)
SELECT 
    country,
    campaign,
    event_count,
    unique_users,
    sessions,
    pct_of_country_events,
    -- Add context: is this campaign also top in other countries?
    CASE 
        WHEN COUNT(*) OVER (PARTITION BY campaign) > 1 
        THEN 'Top in multiple countries' 
        ELSE 'Unique to this country' 
    END AS campaign_insight
FROM 
    ranked_campaigns
WHERE 
    rank_num = 1
ORDER BY 
    country;

/* Expected Results:
   - US: 'black_friday' should be top with highest event count
   - CA: Could be 'black_friday' or 'fall_sale' depending on distribution
   - Shows not just the winner but also percentage share
*/
