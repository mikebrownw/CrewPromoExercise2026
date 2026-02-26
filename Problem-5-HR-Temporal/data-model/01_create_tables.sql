-- SQL Server (T-SQL)
-- Complete Data Model for HR/Temporal/Security

-- Create employees table with self-referencing hierarchy
CREATE TABLE employees (
    emp_id INT PRIMARY KEY,
    manager_id INT NULL,
    name VARCHAR(100) NOT NULL,
    dept VARCHAR(50) NOT NULL,
    FOREIGN KEY (manager_id) REFERENCES employees(emp_id)
);

-- Create comp_changes table for salary history (temporal data)
CREATE TABLE comp_changes (
    change_id INT IDENTITY(1,1) PRIMARY KEY,  -- Surrogate key for tracking
    emp_id INT NOT NULL,
    effective_from DATE NOT NULL,
    effective_to DATE NOT NULL,
    salary DECIMAL(18,2) NOT NULL,
    FOREIGN KEY (emp_id) REFERENCES employees(emp_id),
    -- Ensure valid date range
    CONSTRAINT chk_dates CHECK (effective_from <= effective_to)
);

-- Create users table with JSON profile
CREATE TABLE users (
    user_id INT PRIMARY KEY,
    region VARCHAR(50) NOT NULL,
    profile_json NVARCHAR(MAX) NOT NULL,
    -- Ensure valid JSON
    CONSTRAINT chk_valid_json_profile CHECK (ISJSON(profile_json) = 1)
);

-- Create indexes for performance
CREATE INDEX idx_employees_manager ON employees(manager_id);
CREATE INDEX idx_comp_changes_emp_dates ON comp_changes(emp_id, effective_from, effective_to);
CREATE INDEX idx_users_region ON users(region);

PRINT 'HR/Temporal tables created successfully';
