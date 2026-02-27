-- SQL Server (T-SQL) and PostgreSQL examples
-- Purpose: Restrict analysts to only read their region's users

-- =======================================================================
-- PART 1: SQL SERVER IMPLEMENTATION
-- =======================================================================

-- METHOD:  Using a security predicate function (SQL Server 2016+)

-- First, create a schema for security
CREATE SCHEMA Security;
GO

-- Create function that defines the security predicate
CREATE FUNCTION Security.fn_userRegionPredicate(@region VARCHAR(50))
    RETURNS TABLE
    WITH SCHEMABINDING
AS
RETURN (
    SELECT 1 AS can_access
    FROM dbo.users u
    WHERE u.region = @region
        AND -- Get current user's region from application context or mapping table
        -- For demo, assume we have a table mapping users to regions
        @region IN (
            SELECT region 
            FROM dbo.user_permissions 
            WHERE username = SUSER_NAME()
                AND role = 'analyst'
        )
);
GO

-- Create user_permissions table for mapping
CREATE TABLE dbo.user_permissions (
    username VARCHAR(100),
    region VARCHAR(50),
    role VARCHAR(50)
);

-- Insert sample permissions
INSERT INTO dbo.user_permissions VALUES
('DOMAIN\john_analyst', 'North America', 'analyst'),
('DOMAIN\jane_analyst', 'Europe', 'analyst'),
('DOMAIN\admin_user', 'ALL', 'admin');

-- Apply the security policy
CREATE SECURITY POLICY Security.userRegionFilter
ADD FILTER PREDICATE Security.fn_userRegionPredicate(region) 
ON dbo.users;
GO

-- =======================================================================
-- PART 2: POSTGRESQL IMPLEMENTATION
-- =======================================================================

/*
-- PostgreSQL Row-Level Security Example

-- Create users table
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    region VARCHAR(50) NOT NULL,
    profile_json JSONB NOT NULL
);

-- Insert sample data
INSERT INTO users (region, profile_json) VALUES
('North America', '{"role": "analyst", "permissions": ["read"]}'),
('Europe', '{"role": "analyst", "permissions": ["read"]}'),
('Asia Pacific', '{"role": "manager", "permissions": ["read", "write"]}');

-- Create a table to store user permissions
CREATE TABLE user_regions (
    username TEXT PRIMARY KEY,
    region VARCHAR(50),
    role VARCHAR(50)
);

-- Insert some permissions
INSERT INTO user_regions VALUES
('john_analyst', 'North America', 'analyst'),
('jane_analyst', 'Europe', 'analyst'),
('admin_user', NULL, 'admin');  -- NULL means all regions

-- Enable row-level security on the table
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Create policy for analysts (only see their region)
CREATE POLICY analyst_region_policy ON users
    FOR ALL
    USING (
        -- If user is admin, see all
        EXISTS (SELECT 1 FROM user_regions WHERE username = current_user AND role = 'admin')
        OR
        -- If user is analyst, only see their region
        region = (SELECT region FROM user_regions WHERE username = current_user AND role = 'analyst')
    );

-- Grant permissions
GRANT SELECT ON users TO analyst_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON users TO admin_role;

-- Test as different users
-- psql -U john_analyst -d mydb -c "SELECT * FROM users;"
-- Only sees North America users
*/

-- =======================================================================
-- PART 3: TESTING SECURITY
-- =======================================================================

-- Create test users (in real DB, these would be actual logins)
CREATE USER john_analyst WITHOUT LOGIN;
CREATE USER jane_analyst WITHOUT LOGIN;
CREATE USER admin_user WITHOUT LOGIN;

-- Grant permissions
GRANT SELECT ON dbo.vw_users_secured TO john_analyst, jane_analyst, admin_user;

-- Test as different users
EXECUTE AS USER = 'john_analyst';
SELECT 'John Analyst' AS UserName, * FROM dbo.vw_users_secured;
REVERT;

EXECUTE AS USER = 'jane_analyst';
SELECT 'Jane Analyst' AS UserName, * FROM dbo.vw_users_secured;
REVERT;

EXECUTE AS USER = 'admin_user';
SELECT 'Admin User' AS UserName, * FROM dbo.vw_users_secured;
REVERT;
