-- SQL Server (T-SQL)
-- Purpose: Safely handle amount field that may contain text

PRINT '===== QUERY 2:  Assume ledger.amount can be text in some source, how would you handle that data in a
safe manner to ensure it’s an amount? =====';

-- Remove symbols first, then convert, default to 0 if still invalid
SELECT 
    amount,
    ISNULL(
        TRY_CAST(
            REPLACE(REPLACE(amount, '$', ''), ',', '') 
            AS DECIMAL(18,2)
        ), 
        0.00
    ) AS clean_amount
FROM ledger_staging;
