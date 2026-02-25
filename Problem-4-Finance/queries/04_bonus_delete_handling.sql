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

-- =======================================================================
-- APPROACH 3: Full refresh with history (Type 2 SCD style)
-- =======================================================================

-- Add effective date ranges to track history
ALTER TABLE dim_customer ADD 
    effective_start_date DATETIME2 NOT NULL DEFAULT GETDATE(),
    effective_end_date DATETIME2 NULL,
    is_current BIT NOT NULL DEFAULT 1;

-- For records that are no longer in staging, end-date them
UPDATE dim_customer
SET 
    effective_end_date = GETDATE(),
    is_current = 0
WHERE is_current = 1
AND NOT EXISTS (
    SELECT 1 
    FROM staging_accounts s 
    WHERE s.email = dim_customer.email
);

-- Insert new/updated records as current
INSERT INTO dim_customer (
    customer_id, 
    email, 
    updated_at, 
    effective_start_date, 
    effective_end_date, 
    is_current
)
SELECT 
    NEXT VALUE FOR seq_customer_id,
    s.email,
    s.updated_at,
    GETDATE(),
    NULL,
    1
FROM staging_accounts s
WHERE NOT EXISTS (
    SELECT 1 
    FROM dim_customer d 
    WHERE d.email = s.email 
    AND d.is_current = 1
);

-- =======================================================================
-- APPROACH 4: Snapshot comparison with change detection
-- =======================================================================

CREATE PROCEDURE sp_sync_customers_from_staging
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    BEGIN TRANSACTION;
    
    -- Create temp table to hold comparison results
    CREATE TABLE #customer_changes (
        email VARCHAR(100),
        change_type VARCHAR(10),  -- 'INSERT', 'UPDATE', 'DELETE'
        staging_updated_at DATETIME2,
        current_updated_at DATETIME2
    );
    
    -- Identify changes
    INSERT INTO #customer_changes
    SELECT 
        COALESCE(s.email, d.email) AS email,
        CASE 
            WHEN d.customer_id IS NULL THEN 'INSERT'
            WHEN s.email IS NULL THEN 'DELETE'
            WHEN s.updated_at > d.updated_at THEN 'UPDATE'
            ELSE 'NO CHANGE'
        END AS change_type,
        s.updated_at AS staging_updated_at,
        d.updated_at AS current_updated_at
    FROM (
        SELECT email, MAX(updated_at) AS updated_at
        FROM staging_accounts
        WHERE email IS NOT NULL
        GROUP BY email
    ) s
    FULL OUTER JOIN dim_customer d ON s.email = d.email
    WHERE d.customer_id IS NULL  -- INSERT
       OR s.email IS NULL        -- DELETE
       OR s.updated_at > d.updated_at;  -- UPDATE
    
    -- Handle INSERTs
    INSERT INTO dim_customer (customer_id, email, updated_at)
    SELECT 
        NEXT VALUE FOR seq_customer_id,
        email,
        staging_updated_at
    FROM #customer_changes
    WHERE change_type = 'INSERT';
    
    -- Handle UPDATEs
    UPDATE d
    SET 
        updated_at = c.staging_updated_at
    FROM dim_customer d
    INNER JOIN #customer_changes c ON d.email = c.email
    WHERE c.change_type = 'UPDATE';
    
    -- Handle DELETEs (soft delete)
    UPDATE d
    SET 
        is_active = 0,
        deleted_date = GETDATE()
    FROM dim_customer d
    INNER JOIN #customer_changes c ON d.email = c.email
    WHERE c.change_type = 'DELETE';
    
    -- Log the changes
    INSERT INTO dim_customer_audit (email, change_type, change_date)
    SELECT 
        email,
        change_type,
        GETDATE()
    FROM #customer_changes
    WHERE change_type IN ('INSERT', 'UPDATE', 'DELETE');
    
    COMMIT TRANSACTION;
    
    -- Return summary
    SELECT 
        change_type,
        COUNT(*) AS count
    FROM #customer_changes
    GROUP BY change_type;
END;

/* Summary of Delete Handling Approaches:

| Approach | Pros | Cons | Best For |
|----------|------|------|----------|
| Soft Delete (IsActive) | Preserves history, reversible | Requires filtering active records | Most business scenarios |
| Hard Delete with Audit | Clean tables, full audit trail | Can't easily restore | Regulatory compliance |
| Type 2 SCD | Complete history, temporal queries | More complex, more storage | Data warehousing |
| Snapshot Comparison | Explicit change tracking | More complex ETL | High-volume systems |
*/
