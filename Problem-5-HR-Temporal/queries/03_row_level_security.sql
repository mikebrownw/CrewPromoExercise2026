-- SQL Server (T-SQL) and PostgreSQL examples
-- Purpose: Restrict analysts to only read their region's users

-- =======================================================================
-- PART 1: SQL SERVER IMPLEMENTATION
-- =======================================================================

-- METHOD 1: Using a security predicate function (SQL Server 2016+)

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

-- METHOD 2: Using a view with context_info (SQL Server)
-- Simpler approach if you don't have SQL Server 2016+

-- First, create a table mapping database users to regions
CREATE TABLE dbo.user_region_mapping (
    db_username VARCHAR(100) PRIMARY KEY,
    allowed_region VARCHAR(50),
    role VARCHAR(50)
);

-- Insert mappings
INSERT INTO dbo.user_region_mapping VALUES
('DOMAIN\john_analyst', 'North America', 'analyst'),
('DOMAIN\jane_analyst', 'Europe', 'analyst'),
('DOMAIN\admin_user', 'ALL', 'admin');

-- Create a view that filters by current user
CREATE VIEW dbo.vw_users_secured
AS
SELECT u.*
FROM dbo.users u
CROSS APPLY (
    SELECT allowed_region 
    FROM dbo.user_region_mapping 
    WHERE db_username = SUSER_NAME()
) perm
WHERE perm.allowed_region = 'ALL' 
   OR u.region = perm.allowed_region;
GO

-- Test the view (will only show users in your region)
SELECT * FROM dbo.vw_users_secured;

-- METHOD 3: Using a stored procedure with parameter
CREATE PROCEDURE sp_get_users_by_region
    @UserRole VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @UserRegion VARCHAR(50);
    DECLARE @IsAdmin BIT = 0;
    
    -- Get current user's region and role
    SELECT 
        @UserRegion = allowed_region,
        @IsAdmin = CASE WHEN role = 'admin' THEN 1 ELSE 0 END
    FROM dbo.user_region_mapping
    WHERE db_username = SUSER_NAME();
    
    -- Return data with appropriate filtering
    IF @IsAdmin = 1
    BEGIN
        -- Admin sees all
        SELECT * FROM dbo.users;
    END
    ELSE
    BEGIN
        -- Analyst sees only their region
        SELECT * FROM dbo.users
        WHERE region = @UserRegion;
    END
END;
GO

-- =======================================================================
-- PART 2: POSTGRESQL IMPLEMENTATION (as requested)
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
-- PART 3: APPLICATION-LEVEL SECURITY (Alternative)
-- =======================================================================

-- Sometimes simpler to handle in application layer
CREATE PROCEDURE sp_get_users_api
    @RequestingUserID INT,
    @RequestedRegion VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Get requesting user's role and region
    DECLARE @UserRole VARCHAR(50);
    DECLARE @UserRegion VARCHAR(50);
    
    SELECT 
        @UserRole = JSON_VALUE(profile_json, '$.role'),
        @UserRegion = region
    FROM users
    WHERE user_id = @RequestingUserID;
    
    -- Apply security
    IF @UserRole = 'admin'
    BEGIN
        -- Admin can see all or filter by requested region
        IF @RequestedRegion IS NULL
            SELECT * FROM users;
        ELSE
            SELECT * FROM users WHERE region = @RequestedRegion;
    END
    ELSE IF @UserRole = 'analyst'
    BEGIN
        -- Analysts can only see their own region
        SELECT * FROM users WHERE region = @UserRegion;
    END
    ELSE
    BEGIN
        -- Others see nothing
        SELECT 'Access Denied' AS Message;
    END
END;
GO

-- =======================================================================
-- PART 4: TESTING SECURITY
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

/* Summary of Security Approaches:

| Approach | Pros | Cons | Best For |
|----------|------|------|----------|
| RLS (SQL Server 2016+) | Centralized, enforced at DB level | Requires newer SQL Server | Enterprise apps |
| Views with SUSER_NAME() | Works in all versions | Can be bypassed if direct table access | Legacy systems |
| Stored Procedures | Full control, auditable | Must use procs for all access | API-driven apps |
| Application Layer | Flexible, cross-platform | Can be forgotten | Microservices |
| PostgreSQL RLS | Built-in, elegant | PostgreSQL only | PostgreSQL shops |
*/
