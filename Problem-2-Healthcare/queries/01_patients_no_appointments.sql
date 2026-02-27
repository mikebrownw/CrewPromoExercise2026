-- SQL Server (T-SQL)
-- Purpose: List patients with no appointments in the last 12 months
-- Using a reference date that makes sense for the sample data

DECLARE @ReferenceDate DATE = '2026-02-01';  -- Today is Feb 2026
DECLARE @OneYearAgo DATE = DATEADD(year, -1, @ReferenceDate);  -- Feb 2025

SELECT 
    p.patient_id,
    p.name,
    p.region,
    p.created_at AS patient_since,
    -- Get their last appointment
    (SELECT MAX(appt_date) FROM appointments a WHERE a.patient_id = p.patient_id) AS last_appointment_date,
    -- Calculate days since last appointment
    DATEDIFF(day, 
        ISNULL(
            (SELECT MAX(appt_date) FROM appointments a WHERE a.patient_id = p.patient_id), 
            p.created_at
        ), 
        @ReferenceDate
    ) AS days_since_last_activity,
    -- Show which ones qualify
    CASE 
        WHEN (SELECT MAX(appt_date) FROM appointments a WHERE a.patient_id = p.patient_id) IS NULL THEN 'Never had appointment'
        WHEN (SELECT MAX(appt_date) FROM appointments a WHERE a.patient_id = p.patient_id) < @OneYearAgo THEN 'No appointments in last 12 months'
        ELSE 'Active'
    END AS qualification
FROM patients p
WHERE 
    -- Condition: No appointments in last 12 months (as of Feb 2026)
    NOT EXISTS (
        SELECT 1 
        FROM appointments a 
        WHERE a.patient_id = p.patient_id
            AND a.appt_date >= @OneYearAgo  -- Appointments since Feb 2025
            AND a.status IN ('COMPLETED', 'NO_SHOW')
    )
ORDER BY p.created_at DESC;
    )
ORDER BY 
    p.created_at DESC;
