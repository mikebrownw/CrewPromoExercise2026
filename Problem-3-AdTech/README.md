# Problem 3: AdTech (Event JSON, Campaign Analytics, Lateral)

## Schema
- users(user_id PK, country, created_at)
- events(event_id PK, user_id FK, event_time TIMESTAMP, payload_json JSON)
- Example payload_json: {"utm": {"source":"search","campaign":"fall_sale"},"page":"..."}

## Questions
1. Count events by utm.campaign for US, CA in Q4 2025.
2. Extract multiple JSON fields (campaign, source) via a lateral parse if engine supports it (or repeat JSON_VALUE).
3. Return the top campaign by events per country in Q4 2025.
4. Propose a Materialized View for daily events by country/campaign with partitioning on event_time and indexes on (country, event_time).

## SQL Dialect
All solutions written in SQL Server/T-SQL (SSMS 17 compatible) with JSON support.
