-- SQL Server (T-SQL)
-- Sample Data for HR/Temporal/Security Exercises

-- Insert employees (org chart)
INSERT INTO employees (emp_id, manager_id, name, dept) VALUES
-- CEO (top level)
(100, NULL, 'Sarah CEO', 'Executive'),

-- VPs (level 1)
(110, 100, 'Mike VP Engineering', 'Engineering'),
(120, 100, 'Lisa VP Sales', 'Sales'),
(130, 100, 'John VP HR', 'Human Resources'),

-- Directors (level 2)
(111, 110, 'Alice Dir Engineering', 'Engineering'),
(112, 110, 'Bob Dir Architecture', 'Engineering'),
(121, 120, 'Carol Dir Sales East', 'Sales'),
(122, 120, 'Dave Dir Sales West', 'Sales'),
(131, 130, 'Eve Dir Talent', 'Human Resources'),

-- Managers (level 3)
(113, 111, 'Frank Mgr Backend', 'Engineering'),
(114, 111, 'Grace Mgr Frontend', 'Engineering'),
(115, 112, 'Henry Mgr Cloud', 'Engineering'),
(123, 121, 'Ivy Mgr East Region', 'Sales'),  -- Single entry for 123
(124, 122, 'Jack Mgr West Region', 'Sales'),
(125, 122, 'Kelly Mgr Central', 'Sales'),
(132, 131, 'Larry Mgr Recruiting', 'Human Resources'),

-- Individual Contributors (level 4)
(116, 113, 'Mary Engineer', 'Engineering'),
(117, 113, 'Nick Engineer', 'Engineering'),
(118, 114, 'Olivia Engineer', 'Engineering'),
(119, 114, 'Paul Engineer', 'Engineering'),
(126, 123, 'Quinn Sales Rep', 'Sales'),
(127, 124, 'Rachel Sales Rep', 'Sales'),
(128, 125, 'Sam Sales Rep', 'Sales'),
(133, 132, 'Tina Recruiter', 'Human Resources'),
(134, 132, 'Ursula Recruiter', 'Human Resources'),

-- Additional employees for depth testing
(135, 100, 'Victor Advisor', 'Executive'),
(136, 110, 'Wendy Architect', 'Engineering'),
(137, 136, 'Xavier Engineer', 'Engineering'),  -- Level 4
(138, 137, 'Yuki Intern', 'Engineering');      -- Level 5 - deeper hierarchy

-- Note: The cycle comment is fine to keep
-- (100, 138, 'Sarah CEO', 'Executive');  -- Would create cycle CEO -> Intern -> CEO

INSERT INTO comp_changes (emp_id, effective_from, effective_to, salary) VALUES
-- Employee 123 (Ivy) - Salary progression
(123, '2023-01-01', '2023-12-31', 75000.00),
(123, '2024-01-01', '2024-06-30', 80000.00),
(123, '2024-07-01', '2024-12-31', 85000.00),
(123, '2025-01-01', '2025-06-30', 90000.00),
(123, '2025-07-01', '2025-12-31', 95000.00),
(123, '2026-01-01', '9999-12-31', 100000.00),

-- Sarah CEO (100)
(100, '2020-01-01', '2021-12-31', 150000.00),
(100, '2022-01-01', '2023-12-31', 175000.00),
(100, '2024-01-01', '9999-12-31', 200000.00),

-- Mike VP Engineering (110)
(110, '2021-01-01', '2022-12-31', 120000.00),
(110, '2023-01-01', '2024-12-31', 135000.00),
(110, '2025-01-01', '9999-12-31', 145000.00),

-- Alice Dir Engineering (111)
(111, '2022-01-01', '2023-12-31', 95000.00),
(111, '2024-01-01', '9999-12-31', 105000.00),

-- Frank Mgr Backend (113)
(113, '2023-06-01', '2024-05-31', 85000.00),
(113, '2024-06-01', '9999-12-31', 92000.00),

-- Mary Engineer (116)
(116, '2024-01-01', '2024-12-31', 65000.00),
(116, '2025-01-01', '9999-12-31', 70000.00),

-- Yuki Intern (138) - deepest level
(138, '2025-06-01', '2025-08-31', 45000.00),
(138, '2025-09-01', '9999-12-31', 50000.00);
GO

-- =======================================================================
-- STEP 4: Insert users (with JSON profiles)
-- =======================================================================
INSERT INTO users (user_id, region, profile_json) VALUES
(1001, 'North America', '{"role": "analyst", "permissions": ["read", "write"], "preferences": {"theme": "dark", "notifications": true}}'),
(1002, 'North America', '{"role": "manager", "permissions": ["read", "write", "delete"], "preferences": {"theme": "light", "notifications": false}}'),
(1003, 'Europe', '{"role": "analyst", "permissions": ["read"], "preferences": {"theme": "dark", "notifications": true}}'),
(1004, 'Europe', '{"role": "admin", "permissions": ["read", "write", "delete", "admin"], "preferences": {"theme": "system", "notifications": true}}'),
(1005, 'Asia Pacific', '{"role": "analyst", "permissions": ["read"], "preferences": {"theme": "light", "notifications": false}}'),
(1006, 'Asia Pacific', '{"role": "viewer", "permissions": ["read"], "preferences": {"theme": "dark", "notifications": false}}'),
(1007, 'South America', '{"role": "analyst", "permissions": ["read"], "preferences": {"theme": "light", "notifications": true}}'),
(1008, 'South America', '{"role": "manager", "permissions": ["read", "write"], "preferences": {"theme": "dark", "notifications": true}}'),
(1009, 'North America', '{"role": "analyst", "permissions": ["read"], "preferences": {"theme": "system", "notifications": false}}'),
(1010, 'Europe', '{"role": "analyst", "permissions": ["read"], "preferences": {"theme": "light", "notifications": true}}');


-- =======================================================================
-- Verify data loaded
-- =======================================================================
SELECT 'employees' AS table_name, COUNT(*) AS row_count FROM employees
UNION ALL
SELECT 'comp_changes', COUNT(*) FROM comp_changes
UNION ALL
SELECT 'users', COUNT(*) FROM users;

-- Show sample of each table
SELECT TOP 5 * FROM employees ORDER BY emp_id;
SELECT TOP 5 * FROM comp_changes ORDER BY change_id;
SELECT TOP 5 * FROM users ORDER BY user_id;

PRINT 'All HR sample data inserted successfully';

PRINT 'HR sample data inserted successfully';
