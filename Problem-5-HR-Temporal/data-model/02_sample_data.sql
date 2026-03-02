-- SQL Server (T-SQL)
-- Sample Data for HR/Temporal/Security Exercises

-- Create users table only if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'users' AND type = 'U')
BEGIN
    CREATE TABLE users (
        user_id INT PRIMARY KEY,
        region VARCHAR(50) NOT NULL,
        profile_json NVARCHAR(MAX) NOT NULL,
        CONSTRAINT chk_valid_json_profile CHECK (ISJSON(profile_json) = 1)
    );
END

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

PRINT 'HR sample data inserted successfully';
