-- SQL Server (T-SQL)
-- Purpose: Stored procedure to return upcoming scheduled appointments
-- With optional region filtering

PRINT '========== QUERY 3: Create a procedure sp_next_appts(@Region NULL, @FromDate, @ToDate) that returns
upcoming scheduled appointments (filter region if provided). ==========';

CREATE OR ALTER PROCEDURE sp_next_appts
    @Region VARCHAR(50) = NULL,  -- NULL means all regions
    @FromDate DATE,
    @ToDate DATE
AS
BEGIN
    -- Prevent row count messages
    SET NOCOUNT ON;
    
    -- Input validation
    IF @FromDate IS NULL OR @ToDate IS NULL
    BEGIN
        RAISERROR('@FromDate and @ToDate are required parameters', 16, 1);
        RETURN;
    END;
    
    IF @FromDate > @ToDate
    BEGIN
        RAISERROR('@FromDate must be less than or equal to @ToDate', 16, 1);
        RETURN;
    END;
    
    -- Main query
    SELECT 
        a.appt_id,
        a.appt_date,
        a.status,
        p.patient_id,
        p.name AS patient_name,
        p.region,
        p.birth_date,
        -- Calculate patient age for demographic context
        DATEDIFF(year, p.birth_date, GETDATE()) AS patient_age,
        -- Format date for display
        FORMAT(a.appt_date, 'MMMM d, yyyy') AS formatted_date
    FROM 
        appointments a
        INNER JOIN patients p ON a.patient_id = p.patient_id
    WHERE 
        a.appt_date BETWEEN @FromDate AND @ToDate
        AND a.status = 'SCHEDULED'  -- Only future scheduled appointments
        AND (@Region IS NULL OR p.region = @Region)  -- Optional region filter
    ORDER BY 
        a.appt_date,  -- Chronological order
        p.region;
END;
GO

-- Example usage:
-- EXEC sp_next_appts @Region = 'Northeast', @FromDate = '2025-07-01', @ToDate = '2025-12-31';
-- EXEC sp_next_appts @FromDate = '2025-08-01', @ToDate = '2025-08-31';  -- All regions

/* Testing the procedure:
   - Should return patients 1011, 1003, 1015, 1008, 1004, 1012, 1005 from sample data
   - With region filter, should only return matching patients
*/

--------------------------------------------------------

-- Test the logic without creating a procedure (Parameterized Query)
DECLARE @Region VARCHAR(50) = NULL;  -- Change to 'Northeast' to test filtering
DECLARE @FromDate DATE = '2026-01-01';
DECLARE @ToDate DATE = '2026-03-31';

SELECT 
    a.appt_id,
    a.appt_date,
    a.status,
    p.patient_id,
    p.name AS patient_name,
    p.region
FROM appointments a
INNER JOIN patients p ON a.patient_id = p.patient_id
WHERE 
    a.appt_date BETWEEN @FromDate AND @ToDate
    AND a.status = 'SCHEDULED'
    AND (@Region IS NULL OR p.region = @Region)
ORDER BY a.appt_date, p.region;
