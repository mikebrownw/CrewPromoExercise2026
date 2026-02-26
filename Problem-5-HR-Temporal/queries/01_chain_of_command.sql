-- SQL Server (T-SQL)
-- Purpose: Return chain of command with depth for each employee
-- Includes cycle prevention

-- =======================================================================
-- METHOD 1: Recursive CTE with cycle detection
-- =======================================================================

WITH EmployeeHierarchy AS (
    -- Anchor: Start with employees who have no manager (top level)
    SELECT 
        emp_id,
        manager_id,
        name,
        dept,
        0 AS depth,
        CAST(emp_id AS VARCHAR(MAX)) AS path,
        CAST(name AS VARCHAR(MAX)) AS chain
    FROM employees
    WHERE manager_id IS NULL
    
    UNION ALL
    
    -- Recursive: Join employees to their managers
    SELECT 
        e.emp_id,
        e.manager_id,
        e.name,
        e.dept,
        h.depth + 1 AS depth,
        CAST(h.path + '->' + CAST(e.emp_id AS VARCHAR(10)) AS VARCHAR(MAX)) AS path,
        CAST(h.chain + ' -> ' + e.name AS VARCHAR(MAX)) AS chain
    FROM employees e
    INNER JOIN EmployeeHierarchy h ON e.manager_id = h.emp_id
    -- Prevent cycles: Check if employee already appears in path
    WHERE h.path NOT LIKE '%' + CAST(e.emp_id AS VARCHAR(10)) + '%'
)
SELECT 
    emp_id,
    name,
    dept,
    manager_id,
    depth,
    path AS hierarchy_path,
    chain AS reporting_chain
FROM EmployeeHierarchy
ORDER BY depth, dept, name;

-- =======================================================================
-- METHOD 2: Show full org tree with indentation
-- =======================================================================

WITH OrgTree AS (
    SELECT 
        emp_id,
        manager_id,
        name,
        dept,
        0 AS depth,
        CAST(name AS VARCHAR(MAX)) AS indent_name
    FROM employees
    WHERE manager_id IS NULL
    
    UNION ALL
    
    SELECT 
        e.emp_id,
        e.manager_id,
        e.name,
        e.dept,
        o.depth + 1,
        CAST(REPLICATE('    ', o.depth + 1) + e.name AS VARCHAR(MAX)) AS indent_name
    FROM employees e
    INNER JOIN OrgTree o ON e.manager_id = o.emp_id
    WHERE o.path NOT LIKE '%' + CAST(e.emp_id AS VARCHAR(10)) + '%'
)
SELECT 
    emp_id,
    indent_name AS org_chart_display,
    dept,
    depth
FROM OrgTree
ORDER BY 
    -- Sort to show tree structure
    CASE WHEN manager_id IS NULL THEN emp_id ELSE manager_id END,
    depth,
    name;

-- =======================================================================
-- METHOD 3: Get chain for a specific employee
-- =======================================================================

CREATE OR ALTER PROCEDURE sp_get_employee_chain
    @EmployeeID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    WITH EmployeeChain AS (
        -- Start with the specified employee
        SELECT 
            emp_id,
            manager_id,
            name,
            dept,
            0 AS depth_up,
            CAST(name AS VARCHAR(MAX)) AS reporting_chain_up
        FROM employees
        WHERE emp_id = @EmployeeID
        
        UNION ALL
        
        -- Go up the chain (to managers)
        SELECT 
            e.emp_id,
            e.manager_id,
            e.name,
            e.dept,
            c.depth_up + 1,
            CAST(e.name + ' -> ' + c.reporting_chain_up AS VARCHAR(MAX))
        FROM employees e
        INNER JOIN EmployeeChain c ON e.emp_id = c.manager_id
    )
    SELECT 
        emp_id,
        name,
        dept,
        depth_up AS levels_above,
        reporting_chain_up
    FROM EmployeeChain
    ORDER BY depth_up DESC;  -- CEO first, then down to employee
    
    -- Also show who reports to this employee (down the chain)
    SELECT 
        emp_id,
        name,
        dept,
        'Direct Report' AS relationship
    FROM employees
    WHERE manager_id = @EmployeeID;
END;
GO

-- Test the procedure
EXEC sp_get_employee_chain @EmployeeID = 138;  -- Yuki the Intern

-- =======================================================================
-- CYCLE PREVENTION EXPLANATION
-- =======================================================================

/*
Why cycle prevention is critical:

Without cycle prevention, if there's a loop (e.g., A manages B, B manages C, C manages A),
the recursive CTE would run infinitely until it hits the recursion limit.

The line that prevents cycles:
    WHERE h.path NOT LIKE '%' + CAST(e.emp_id AS VARCHAR(10)) + '%'

How it works:
- path column tracks all employees seen so far: '100->110->111'
- For each new employee, check if they're already in the path
- If they are, don't recurse (prevents cycle)

Example of a cycle we'd catch:
    Path: '100->110->111->100' (CEO appears twice)
    Query sees 100 already in path and stops recursion
*/
