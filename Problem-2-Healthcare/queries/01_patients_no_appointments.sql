SELECT 
    p.patient_id,
    p.name,
    p.region,
    MAX(a.appt_date) AS last_appointment_date
FROM patients p
LEFT JOIN appointments a ON p.patient_id = a.patient_id
    AND a.status IN ('COMPLETED', 'NO_SHOW')
GROUP BY p.patient_id, p.name, p.region
HAVING 
    MAX(a.appt_date) IS NULL 
    OR MAX(a.appt_date) < DATEADD(year, -1, GETDATE())
ORDER BY p.created_at DESC;
