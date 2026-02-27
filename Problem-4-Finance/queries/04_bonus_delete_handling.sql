-- SQL Server (T-SQL)
-- Purpose: Handle deletes when staging_accounts is a full snapshot
-- Bonus question: How to handle records that exist in dim_customer but not in staging

-- =======================================================================
-- APPROACH 1: Soft deletes (recommended for dimensional tables)
-- =======================================================================

-- First, add an IsActive flag and DeletedDate to dim_customer
ALTER TABLE dim_customer ADD 
    is_active BIT NOT NULL DEFAULT 1,
    deleted_date DATETIME2 NULL;

-- Now perform a full sync with staging (which represents ALL current accounts)
WITH latest_staging AS (
    SELECT 
        email,
        MAX(updated_at) AS updated_at
    FROM staging_accounts
    WHERE email IS NOT NULL
    GROUP BY email
)
MERGE dim_customer AS target
USING latest_staging AS source ON target.email = source.email

-- Update existing active records if newer
WHEN MATCHED AND target.is_active = 1 AND source.updated_at > target.updated_at THEN
    UPDATE SET 
        updated_at = source.updated_at,
        deleted_date = NULL,
        is_active = 1

-- Insert new records
WHEN NOT MATCHED BY TARGET THEN
    INSERT (customer_id, email, updated_at, is_active, deleted_date)
    VALUES (
        NEXT VALUE FOR seq_customer_id,
        source.email,
        source.updated_at,
        1,
        NULL
    )

-- Soft delete records that are in dim_customer but NOT in staging
WHEN NOT MATCHED BY SOURCE AND target.is_active = 1 THEN
    UPDATE SET 
        is_active = 0,
        deleted_date = GETDATE();

-- =======================================================================
-- APPROACH 2: Hard delete with audit trail
-- =======================================================================

-- Create an audit table for deleted customers
CREATE TABLE dim_customer_audit (
    audit_id INT IDENTITY PRIMARY KEY,
    customer_id INT,
    email VARCHAR(100),
    updated_at DATETIME2,
    deleted_at DATETIME2,
    deleted_by VARCHAR(100)
);

BEGIN TRANSACTION;

-- Step 1: Insert records to be deleted into audit table
INSERT INTO dim_customer_audit (customer_id, email, updated_at, deleted_at, deleted_by)
SELECT 
    customer_id,
    email,
    updated_at,
    GETDATE(),
    SYSTEM_USER
FROM dim_customer d
WHERE NOT EXISTS (
    SELECT 1 
    FROM staging_accounts s 
    WHERE s.email = d.email
);

-- Step 2: Delete records not in staging
DELETE FROM dim_customer
WHERE NOT EXISTS (
    SELECT 1 
    FROM staging_accounts s 
    WHERE s.email = dim_customer.email
);

COMMIT TRANSACTION;
