-- =======================================================================
-- PROBLEM 4: FINANCE - VIEW ALL TABLES
-- =======================================================================

-- =======================================================================
-- PART 1: View accounts table
-- =======================================================================
SELECT '=== ACCOUNTS TABLE ===' AS section;
SELECT 
    account_id,
    name,
    balance
FROM accounts
ORDER BY account_id;

-- =======================================================================
-- PART 2: View ledger table (transaction history)
-- =======================================================================
SELECT '=== LEDGER TABLE ===' AS section;
SELECT 
    txn_id,
    account_id,
    txn_time,
    amount,
    currency,
    memo
FROM ledger
ORDER BY txn_time DESC;

-- =======================================================================
-- PART 3: View staging_accounts (source data)
-- =======================================================================
SELECT '=== STAGING_ACCOUNTS TABLE ===' AS section;
SELECT 
    account_id,
    email,
    updated_at
FROM staging_accounts
ORDER BY account_id;

-- =======================================================================
-- PART 4: View dim_customer (target dimension)
-- =======================================================================
SELECT '=== DIM_CUSTOMER TABLE ===' AS section;
SELECT 
    customer_id,
    email,
    updated_at
FROM dim_customer
ORDER BY customer_id;

-- =======================================================================
-- PART 5: View ledger_staging (dirty data for testing)
-- =======================================================================
SELECT '=== LEDGER_STAGING TABLE (dirty data) ===' AS section;
SELECT 
    txn_id,
    account_id,
    txn_time,
    amount AS original_amount_text,
    currency,
    memo
FROM ledger_staging
ORDER BY txn_id;

-- =======================================================================
-- PART 6: View ledger_errors (invalid records)
-- =======================================================================
SELECT '=== LEDGER_ERRORS TABLE ===' AS section;
SELECT 
    error_id,
    txn_id,
    original_amount,
    error_date
FROM ledger_errors
ORDER BY error_date DESC;

-- =======================================================================
-- PART 7: Summary counts
-- =======================================================================
SELECT '=== TABLE COUNTS ===' AS section;
SELECT 'accounts' AS table_name, COUNT(*) AS row_count FROM accounts
UNION ALL
SELECT 'ledger', COUNT(*) FROM ledger
UNION ALL
SELECT 'staging_accounts', COUNT(*) FROM staging_accounts
UNION ALL
SELECT 'dim_customer', COUNT(*) FROM dim_customer
UNION ALL
SELECT 'ledger_staging', COUNT(*) FROM ledger_staging
UNION ALL
SELECT 'ledger_errors', COUNT(*) FROM ledger_errors
ORDER BY table_name;
