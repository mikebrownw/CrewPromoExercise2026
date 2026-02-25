-- SQL Server (T-SQL)
-- Purpose: Upsert staging_accounts into dim_customer
-- Newer updated_at wins, insert new records

-- =======================================================================
-- METHOD 1: MERGE statement (SQL Server 2008+)
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

-- =======================================================================
-- METHOD 2: Separate UPDATE and INSERT (more control)
-- =======================================================================

BEGIN TRANSACTION;

-- Step 1: Update existing records where source is newer
UPDATE dim_customer
SET 
    updated_at = s.updated_at
FROM dim_customer d
INNER JOIN (
    SELECT 
        email,
        MAX(updated_at) AS updated_at
    FROM staging_accounts
    WHERE email IS NOT NULL
    GROUP BY email
) s ON d.email = s.email
WHERE s.updated_at > d.updated_at;

-- Step 2: Insert new records (not already in dim_customer)
INSERT INTO dim_customer (customer_id, email, updated_at)
SELECT 
    ROW_NUMBER() OVER (ORDER BY s.email) + ISNULL(MAX(d.customer_id), 1000) AS customer_id,
    s.email,
    s.updated_at
FROM (
    SELECT 
        email,
        MAX(updated_at) AS updated_at
    FROM staging_accounts
    WHERE email IS NOT NULL
    GROUP BY email
) s
CROSS JOIN (SELECT MAX(customer_id) AS max_id FROM dim_customer) d
LEFT JOIN dim_customer target ON s.email = target.email
WHERE target.email IS NULL;

COMMIT TRANSACTION;

-- =======================================================================
-- METHOD 3: Using CTE for clarity
-- =======================================================================

WITH latest_staging AS (
    SELECT 
        email,
        MAX(updated_at) AS updated_at
    FROM staging_accounts
    WHERE email IS NOT NULL
    GROUP BY email
),
to_update AS (
    SELECT 
        d.customer_id,
        d.email,
        d.updated_at AS current_updated_at,
        s.updated_at AS new_updated_at
    FROM dim_customer d
    INNER JOIN latest_staging s ON d.email = s.email
    WHERE s.updated_at > d.updated_at
),
to_insert AS (
    SELECT 
        s.email,
        s.updated_at
    FROM latest_staging s
    LEFT JOIN dim_customer d ON s.email = d.email
    WHERE d.email IS NULL
)
-- Perform update
UPDATE dim_customer
SET updated_at = u.new_updated_at
FROM dim_customer d
INNER JOIN to_update u ON d.customer_id = u.customer_id;

-- Perform insert
INSERT INTO dim_customer (customer_id, email, updated_at)
SELECT 
    (SELECT ISNULL(MAX(customer_id), 1000) + ROW_NUMBER() OVER (ORDER BY email) FROM dim_customer),
    email,
    updated_at
FROM to_insert;

-- =======================================================================
-- METHOD 4: Using SEQUENCE for customer_id generation (recommended)
-- =======================================================================

CREATE SEQUENCE seq_customer_id START WITH 1000 INCREMENT BY 1;

MERGE dim_customer AS target
USING (
    SELECT DISTINCT
        email,
        MAX(updated_at) OVER (PARTITION BY email) AS updated_at
    FROM staging_accounts
    WHERE email IS NOT NULL
) AS source ON target.email = source.email

WHEN MATCHED AND source.updated_at > target.updated_at THEN
    UPDATE SET target.updated_at = source.updated_at

WHEN NOT MATCHED THEN
    INSERT (customer_id, email, updated_at)
    VALUES (NEXT VALUE FOR seq_customer_id, source.email, source.updated_at)

OUTPUT $action, inserted.*;

/* Testing the upsert:
   Before: dim_customer has john.doe@email.com (2025-01-01)
   Staging has john.doe@email.com (2025-02-20) - should update
   Staging has new.customer@email.com - should insert
   Staging has duplicate emails - should be deduplicated
*/
