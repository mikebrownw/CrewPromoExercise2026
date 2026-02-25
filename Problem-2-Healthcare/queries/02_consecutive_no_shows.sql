-- SQL Server (T-SQL)
-- Purpose: Identify patients who had 3 or more consecutive NO_SHOW appointments
-- Uses window functions to detect patterns in appointment sequences

WITH patient_appointments AS (
    -- First, get all appointments in order per patient
    SELECT 
        patient_id,
        appt_id,
        appt_date,
        status,
        -- Row number to establish sequence
        ROW_NUMBER() OVER (
            PARTITION BY patient_id 
            ORDER BY appt_date
        ) AS seq_num
    FROM 
        appointments
    WHERE 
        status IN ('NO_SHOW', 'COMPLETED')  -- Only relevant statuses for pattern
),
no_show_groups AS (
    -- Identify groups of consecutive NO_SHOWs
    SELECT 
        patient_id,
        appt_id,
        appt_date,
        status,
        seq_num,
        -- Assign a group ID to each streak of NO_SHOWs
        seq_num - ROW_NUMBER() OVER (
            PARTITION BY patient_id 
            ORDER BY seq_num
        ) AS grp
    FROM 
        patient_appointments
    WHERE 
        status = 'NO_SHOW'
),
streak_lengths AS (
    -- Calculate length of each NO_SHOW streak
    SELECT 
        patient_id,
        grp,
        COUNT(*) AS streak_length,
        MIN(appt_date) AS streak_start,
        MAX(appt_date) AS streak_end
    FROM 
        no_show_groups
    GROUP BY 
        patient_id, grp
    HAVING 
        COUNT(*) >= 3  -- At least 3 consecutive NO_SHOWs
)
-- Return patients with 3+ consecutive NO_SHOWs
SELECT DISTINCT
    p.patient_id,
    p.name,
    p.region,
    s.streak_length,
    s.streak_start,
    s.streak_end
FROM 
    streak_lengths s
    INNER JOIN patients p ON s.patient_id = p.patient_id
ORDER BY 
    s.streak_length DESC,
    p.name;

/* Explanation:
   - Uses "gaps and islands" technique to identify consecutive NO_SHOWs
   - The key: seq_num - ROW_NUMBER() creates constant group ID for consecutive rows
   - Patients with 1001 and 1006 in sample data should appear
*/
