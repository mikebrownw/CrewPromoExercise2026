# Problem 5: HR / Org & Temporal / Security

## Schema
- employees(emp_id PK, manager_id FK NULL, name, dept)
- comp_changes(emp_id FK, effective_from DATE, effective_to DATE, salary NUMERIC(18,2))
- users(user_id PK, region, profile_json JSON)

## Questions
1. Return the chain of command with depth for each employee; prevent cycles.
2. What was employee 123's salary on 2025-08-15?
3. Only allow analysts to read their region's users (Postgres example).

## SQL Dialect
All solutions written in SQL Server/T-SQL (SSMS 17 compatible) with hierarchy and temporal handling.
