-- SQL Server (T-SQL)
-- Purpose: Return chain of command with depth for each employee
-- Includes cycle prevention

PRINT '========== QUERY 1: Return the chain of command with depth for each employee; prevent cycles.
 ==========';

-- Method 2: Show full org tree with indentation (WITH cycle prevention)
WITH OrgTree AS (
    -- Anchor: Start with top-level employees (no manager)
    SELECT 
        emp_id,
        manager_id,
        name,
        dept,
        0 AS depth,
        CAST(name AS VARCHAR(MAX)) AS indent_name,
        -- Add path to track hierarchy and detect cycles
        CAST(emp_id AS VARCHAR(MAX)) AS path  -- Track which employees we've seen
    FROM employees
    WHERE manager_id IS NULL
    
    UNION ALL
    
    -- Recursive: Add direct reports
    SELECT 
        e.emp_id,
        e.manager_id,
        e.name,
        e.dept,
        o.depth + 1,
        -- Add indentation based on depth level
        CAST(REPLICATE('    ', o.depth + 1) + e.name AS VARCHAR(MAX)) AS indent_name,
        -- Append current employee to path
        CAST(o.path + '->' + CAST(e.emp_id AS VARCHAR(10)) AS VARCHAR(MAX)) AS path
    FROM employees e
    INNER JOIN OrgTree o ON e.manager_id = o.emp_id
    -- CRITICAL: Prevent cycles by checking if employee already in path
    WHERE o.path NOT LIKE '%' + CAST(e.emp_id AS VARCHAR(10)) + '%'
)
SELECT 
    emp_id,
    indent_name AS org_chart_display,
    dept,
    depth,
    path  -- Optional: show the path for debugging
FROM OrgTree
ORDER BY 
    -- Sort to show tree structure (top-level first, then by depth)
    CASE WHEN manager_id IS NULL THEN emp_id ELSE manager_id END,
    depth,
    name;
