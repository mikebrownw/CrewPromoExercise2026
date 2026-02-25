-- SQL Server (T-SQL)
-- Purpose: List patients with no appointments in the last 12 months
-- Sorted with newest patients first

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
    DATEDIFF(day, 
        ISNULL((
            SELECT MAX(appt_date) 
            FROM appointments a 
            WHERE a.patient_id = p.patient_id
        ), p.created_at),  -- If no appointments, use creation date
        GETDATE()
    ) AS days_since_last_activity
FROM 
    patients p
WHERE 
    -- No appointments in last 12 months
    NOT EXISTS (
        SELECT 1 
        FROM appointments a 
        WHERE a.patient_id = p.patient_id
            AND a.appt_date >= DATEADD(year, -1, GETDATE())
            AND a.status IN ('COMPLETED', 'NO_SHOW')  -- Exclude future SCHEDULED
    )
    -- AND also include patients with NO appointments at all
ORDER BY 
    p.created_at DESC;  -- Newest patients first

/* Business Value:
   - Identifies patients at risk of churn
   - Helps target outreach campaigns
   - Newest patients first prioritizes recent acquisitions
*/
