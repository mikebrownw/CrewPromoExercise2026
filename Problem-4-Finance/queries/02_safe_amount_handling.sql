-- SQL Server (T-SQL)
-- Purpose: Safely handle amount field that may contain text

PRINT '===== Assume ledger.amount can be text in some source, how would you handle that data in a
safe manner to ensure it’s an amount? =====';

-- Use TRY_CAST to safely convert text to numbers
-- Invalid values become NULL instead of crashing

SELECT 
    txn_id,
    -- Safely convert amount text to decimal
    TRY_CAST(amount AS DECIMAL(18,2)) AS safe_amount,
    -- Identify problematic records
    CASE 
        WHEN TRY_CAST(amount AS DECIMAL(18,2)) IS NULL 
        THEN 'Invalid amount format'
        ELSE 'Valid'
    END AS amount_status
FROM ledger_staging;
