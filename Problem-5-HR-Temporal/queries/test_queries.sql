-- Test Question 1: Chain of command
SELECT * FROM EmployeeHierarchy ORDER BY depth, dept;

-- Test Question 2: Salary on specific date
SELECT dbo.fn_get_salary_on_date(123, '2025-08-15') AS salary_on_aug15;

-- Test Question 3: Security (if you have test logins)
EXEC sp_get_users_by_region;
