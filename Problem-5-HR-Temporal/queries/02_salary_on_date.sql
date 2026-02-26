-- SQL Server (T-SQL)
-- Purpose: Find employee 123's salary on 2025-08-15
-- Demonstrates temporal query patterns

-- =======================================================================
-- METHOD 1: Basic query for specific date
-- =======================================================================

SELECT 
    e.emp_id,
    e.name,
    e.dept,
    c.salary,
    c.effective_from,
    c.effective_to,
    -- Show if this is current or historical
    CASE 
        WHEN GETDATE() BETWEEN c.effective_from AND c.effective_to THEN 'Current'
        ELSE 'Historical'
    END AS salary_status
FROM employees e
INNER JOIN comp_changes c ON e.emp_id = c.emp_id
WHERE e.emp_id = 123
    AND '2025-08-15' BETWEEN c.effective_from AND c.effective_to;

-- Expected result: 
-- emp_id = 123, salary = 95000.00 (from 2025-07-01 to 2025-12-31)

-- =======================================================================
-- METHOD 2: Show all salaries for employee 123 with context
-- =======================================================================

SELECT 
    e.emp_id,
    e.name,
    c.salary,
    c.effective_from,
    c.effective_to,
    DATEDIFF(day, c.effective_from, c.effective_to) AS days_valid,
    -- Mark the specific date we're interested in
    CASE 
        WHEN '2025-08-15' BETWEEN c.effective_from AND c.effective_to 
        THEN '*** TARGET DATE ***'
        ELSE ''
    END AS target_date_status
FROM employees e
INNER JOIN comp_changes c ON e.emp_id = c.emp_id
WHERE e.emp_id = 123
ORDER BY c.effective_from;

-- =======================================================================
-- METHOD 3: Function to get salary for any employee on any date
-- =======================================================================

CREATE OR ALTER FUNCTION fn_get_salary_on_date
(
    @EmployeeID INT,
    @TargetDate DATE
)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @Salary DECIMAL(18,2);
    
    SELECT @Salary = salary
    FROM comp_changes
    WHERE emp_id = @EmployeeID
        AND @TargetDate BETWEEN effective_from AND effective_to;
    
    RETURN @Salary;
END;
GO

-- Test the function
SELECT 
    dbo.fn_get_salary_on_date(123, '2025-08-15') AS salary_on_aug15,
    dbo.fn_get_salary_on_date(123, '2024-03-15') AS salary_on_mar15,
    dbo.fn_get_salary_on_date(123, '2026-02-01') AS salary_on_feb26;  -- Future date

-- =======================================================================
-- METHOD 4: Stored procedure with validation and range checking
-- =======================================================================

CREATE OR ALTER PROCEDURE sp_get_salary_history
    @EmployeeID INT,
    @AsOfDate DATE = NULL  -- NULL means most recent
AS
BEGIN
    SET NOCOUNT ON;
    
    -- If no date provided, use current date
    IF @AsOfDate IS NULL
        SET @AsOfDate = GETDATE();
    
    -- Check if employee exists
    IF NOT EXISTS (SELECT 1 FROM employees WHERE emp_id = @EmployeeID)
    BEGIN
        SELECT 'Employee not found' AS Error;
        RETURN;
    END;
    
    -- Get salary information
    SELECT 
        e.emp_id,
        e.name,
        e.dept,
        c.salary,
        c.effective_from,
        c.effective_to,
        -- Additional context
        CASE 
            WHEN @AsOfDate < c.effective_from THEN 'Future effective date'
            WHEN @AsOfDate > c.effective_to THEN 'Expired'
            WHEN @AsOfDate BETWEEN c.effective_from AND c.effective_to THEN 'Active on date'
            ELSE 'Not applicable'
        END AS date_status,
        -- Show if this is the current active salary
        CASE 
            WHEN GETDATE() BETWEEN c.effective_from AND c.effective_to 
            THEN 'Current active'
            ELSE ''
        END AS current_status
    FROM employees e
    LEFT JOIN comp_changes c ON e.emp_id = c.emp_id
    WHERE e.emp_id = @EmployeeID
        AND (@AsOfDate BETWEEN c.effective_from AND c.effective_to OR @AsOfDate IS NULL)
    ORDER BY c.effective_from;
END;
GO

-- Test the procedure
EXEC sp_get_salary_history @EmployeeID = 123, @AsOfDate = '2025-08-15';
EXEC sp_get_salary_history @EmployeeID = 123;  -- Most recent

-- =======================================================================
-- METHOD 5: Temporal table alternative (SQL Server 2016+)
-- =======================================================================

/*
If using SQL Server 2016+, you could create a temporal table:

CREATE TABLE comp_changes_temporal (
    emp_id INT NOT NULL,
    salary DECIMAL(18,2) NOT NULL,
    effective_from DATETIME2 GENERATED ALWAYS AS ROW START,
    effective_to DATETIME2 GENERATED ALWAYS AS ROW END,
    PERIOD FOR SYSTEM_TIME (effective_from, effective_to)
)
WITH (SYSTEM_VERSIONING = ON);

Then query would be:
SELECT salary 
FROM comp_changes_temporal
FOR SYSTEM_TIME AS OF '2025-08-15'
WHERE emp_id = 123;
*/

-- =======================================================================
-- VALIDATION: Check for gaps or overlaps
-- =======================================================================

-- Check for gaps in salary history
WITH date_ranges AS (
    SELECT 
        emp_id,
        effective_from,
        effective_to,
        LAG(effective_to) OVER (PARTITION BY emp_id ORDER BY effective_from) AS prev_effective_to
    FROM comp_changes
    WHERE emp_id = 123
)
SELECT 
    emp_id,
    effective_from,
    effective_to,
    prev_effective_to,
    CASE 
        WHEN prev_effective_to IS NULL THEN 'First record'
        WHEN effective_from = DATEADD(day, 1, prev_effective_to) THEN 'Continuous'
        WHEN effective_from > DATEADD(day, 1, prev_effective_to) THEN 'GAP DETECTED'
        WHEN effective_from < DATEADD(day, 1, prev_effective_to) THEN 'OVERLAP DETECTED'
        ELSE 'Unknown'
    END AS continuity_check
FROM date_ranges;

/* Answer to Question 2:
   Employee 123's salary on 2025-08-15 was $95,000.00
   This is from the comp_changes record: 
   effective_from = 2025-07-01, effective_to = 2025-12-31
*/
