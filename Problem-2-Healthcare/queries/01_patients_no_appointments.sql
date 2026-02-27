-- SQL Server (T-SQL)
-- Purpose: List patients with no appointments in the last 12 months (as of March 1, 2026)
-- Using a fixed reference date for consistent testing

DECLARE @ReferenceDate DATE = '2026-03-01';  -- Fixed reference date for testing

SELECT 
    p.patient_id,
    p.name,
    p.region,
    p.created_at AS patient_since,
    -- Calculate when their last appointment was (if any)
    (
        SELECT MAX(appt_date) 
        FROM appointments a 
        WHERE a.patient_id = p.patient_id
    ) AS last_appointment_date,
    -- Calculate days since last activity
    DATEDIFF(day, 
        ISNULL((
            SELECT MAX(appt_date) 
            FROM appointments a 
            WHERE a.patient_id = p.patient_id
        ), p.created_at),
        @ReferenceDate
    ) AS days_since_last_activity,
    -- Show if it's been >365 days
    CASE 
        WHEN DATEDIFF(day, 
            ISNULL((
                SELECT MAX(appt_date) 
                FROM appointments a 
                WHERE a.patient_id = p.patient_id
            ), p.created_at),
            @ReferenceDate
        ) > 365 THEN 'Yes - No activity in 12+ months'
        ELSE 'No - Recent activity'
    END AS no_activity_12months
FROM 
    patients p
WHERE 
    -- No appointments in last 12 months (using fixed date)
    NOT EXISTS (
        SELECT 1 
        FROM appointments a 
        WHERE a.patient_id = p.patient_id
            AND a.appt_date >= DATEADD(year, -1, @ReferenceDate)
            AND a.status IN ('COMPLETED', 'NO_SHOW')
    )
ORDER BY 
    p.created_at DESC;
