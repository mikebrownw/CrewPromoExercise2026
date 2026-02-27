-- SQL Server (T-SQL)
-- Purpose: Upsert staging_accounts into dim_customer
-- Newer updated_at wins, insert new records

-- =======================================================================
PRINT 'QUERY 3:  Show some SQL to Upsert staging_accounts into dim_customer (newer updated_at wins)
and insert any new records';
-- =======================================================================

MERGE dim_customer AS target
USING (
    -- Deduplicate staging data - keep newest per email
    SELECT 
        -- Generate new customer_id for potential inserts
        -- For updates, we'll keep existing ID
        email,
        MAX(updated_at) AS updated_at,
        MAX(account_id) AS account_id  -- Not used in dim, but for reference
    FROM staging_accounts
    WHERE email IS NOT NULL  -- Skip NULL emails
    GROUP BY email
) AS source ON target.email = source.email

-- When matched, update if source is newer
WHEN MATCHED AND source.updated_at > target.updated_at THEN
    UPDATE SET 
        target.updated_at = source.updated_at

-- When not matched, insert new record
WHEN NOT MATCHED BY TARGET THEN
    INSERT (customer_id, email, updated_at)
    VALUES (
        -- Generate new customer_id (using sequence or max+1)
        (SELECT ISNULL(MAX(customer_id), 1000) + 1 FROM dim_customer),
        source.email,
        source.updated_at
    )

-- Optional: Output the results
OUTPUT 
    $action AS action_taken,
    inserted.customer_id,
    inserted.email,
    inserted.updated_at,
    deleted.updated_at AS old_updated_at;
