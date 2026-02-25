# Problem 2: Healthcare (Appointments & Patient Gaps)

## Schema
- patients(patient_id PK, name, birth_date, created_at, region)
- appointments(appt_id PK, patient_id FK, appt_date DATE, status) -- 'SCHEDULED','COMPLETED','NO_SHOW'

## Questions
1. List patients with no appointments in the last 12 months, newest patients first.
2. Return patients who had 3 consecutive NO_SHOWs at any point.
3. Create a procedure sp_next_appts(@Region NULL, @FromDate, @ToDate) that returns upcoming scheduled appointments (filter region if provided).
4. Create view vw_monthly_no_show_rate and discuss indexes (e.g., (patient_id, appt_date)), and partitioning by appt_date.

## SQL Dialect
All solutions written in SQL Server/T-SQL (SSMS 17 compatible).
