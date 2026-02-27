-- SQL Server (T-SQL)
-- Purpose: Find employee 123's salary on 2025-08-15
-- Demonstrates temporal query patterns


-- =======================================================================
--What was employee 123’s salary on 2025‑08‑15?
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
