SELECT '===== PATIENTS =====' AS [Header];
SELECT * FROM patients;

SELECT '===== APPOINTMENTS =====' AS [Header];
SELECT * FROM appointments;

--------------------------------------------------

-- Test Question 1
SELECT * FROM patients_with_no_recent_appts;

-- Test Question 2
EXEC find_patients_with_consecutive_no_shows @min_streak = 3;

-- Test Question 3
EXEC get_upcoming_appointments 
    @region = 'Northeast', 
    @from_date = '2025-07-01', 
    @to_date = '2025-12-31';

-- Test Question 4
SELECT * FROM vw_monthly_no_show_stats 
WHERE year = 2025 
ORDER BY month, region;
