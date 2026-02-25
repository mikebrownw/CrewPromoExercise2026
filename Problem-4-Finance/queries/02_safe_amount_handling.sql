-- SQL Server (T-SQL)
-- Purpose: Safely handle amount field that may contain text
-- Demonstrates multiple approaches to clean and validate data

-- =======================================================================
-- APPROACH 1: Clean data during load with TRY_CAST
-- =======================================================================

-- Create a staging table with amount as VARCHAR (simulating dirty source)
CREATE TABLE ledger_staging (
    txn_id INT,
    account_id INT,
    txn_time DATETIME2,
    amount VARCHAR(50),  -- Deliberately VARCHAR to simulate dirty data
    currency VARCHAR(3),
    memo NVARCHAR(255)
);

-- Insert sample dirty data
INSERT INTO ledger_staging VALUES
(2001, 1, '2025-03-01 10:00:00', '100.00', 'USD', 'Clean amount'),
(2002, 2, '2025-03-01 10:30:00', '$50.00', 'USD', 'Has dollar sign'),
(2003, 3, '2025-03-01 11:00:00', '1,234.56', 'USD', 'Has comma'),
(2004, 4, '2025-03-01 11:30:00', '(25.00)', 'USD', 'Parentheses for negative'),
(2005, 5, '2025-03-01 12:00:00', '75.00 USD', 'USD', 'Has currency text'),
(2006, 1, '2025-03-01 12:30:00', 'INVALID', 'USD', 'Completely invalid'),
(2007, 2, '2025-03-01 13:00:00', '--100', 'USD', 'Bad format'),
(2008, 3, '2025-03-01 13:30:00', NULL, 'USD', 'NULL value');

-- Clean and load into main ledger
INSERT INTO ledger (txn_id, account_id, txn_time, amount, currency, memo)
SELECT 
    txn_id,
    account_id,
    txn_time,
    -- Multiple cleaning steps
    CASE 
        -- Remove dollar signs, commas, and spaces
        WHEN TRY_CAST(REPLACE(REPLACE(REPLACE(amount, '$', ''), ',', ''), ' ', '') AS DECIMAL(18,2)) IS NOT NULL
            THEN TRY_CAST(REPLACE(REPLACE(REPLACE(amount, '$', ''), ',', ''), ' ', '') AS DECIMAL(18,2))
        -- Handle parentheses for negative numbers: (100) -> -100
        WHEN amount LIKE '(%' AND amount LIKE '%)' 
            THEN -1 * TRY_CAST(REPLACE(REPLACE(REPLACE(REPLACE(amount, '(', ''), ')', ''), '$', ''), ',', '') AS DECIMAL(18,2))
        -- Extract number from strings like "75.00 USD"
        WHEN PATINDEX('%[0-9.]%', amount) > 0 
            THEN TRY_CAST(SUBSTRING(amount, PATINDEX('%[0-9.]%', amount), 
                           LEN(amount)) AS DECIMAL(18,2))
        ELSE NULL
    END AS clean_amount,
    currency,
    CONCAT('Cleaned from: ', amount, ' | ', memo) AS memo
FROM ledger_staging
WHERE 
    -- Filter out records that couldn't be cleaned
    CASE 
        WHEN TRY_CAST(REPLACE(REPLACE(REPLACE(amount, '$', ''), ',', ''), ' ', '') AS DECIMAL(18,2)) IS NOT NULL THEN 1
        WHEN amount LIKE '(%' AND amount LIKE '%)' THEN 1
        WHEN PATINDEX('%[0-9.]%', amount) > 0 THEN 1
        ELSE 0
    END = 1;

-- =======================================================================
-- APPROACH 2: Create a reusable function
-- =======================================================================

CREATE OR ALTER FUNCTION dbo.fn_clean_amount (@dirty_amount VARCHAR(50))
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @clean DECIMAL(18,2);
    DECLARE @cleaned_string VARCHAR(50);
    
    -- Return NULL for NULL input
    IF @dirty_amount IS NULL
        RETURN NULL;
    
    -- Step 1: Remove currency symbols and common characters
    SET @cleaned_string = REPLACE(@dirty_amount, '$', '');
    SET @cleaned_string = REPLACE(@cleaned_string, '€', '');
    SET @cleaned_string = REPLACE(@cleaned_string, '£', '');
    SET @cleaned_string = REPLACE(@cleaned_string, ',', '');
    SET @cleaned_string = REPLACE(@cleaned_string, ' ', '');
    
    -- Step 2: Handle parentheses for negatives
    IF @cleaned_string LIKE '(%' AND @cleaned_string LIKE '%)'
    BEGIN
        SET @cleaned_string = REPLACE(REPLACE(@cleaned_string, '(', ''), ')', '');
        SET @cleaned_string = '-' + @cleaned_string;
    END
    
    -- Step 3: Extract first number-like pattern
    IF PATINDEX('%[0-9.-]%', @cleaned_string) > 0
    BEGIN
        SET @cleaned_string = SUBSTRING(
            @cleaned_string, 
            PATINDEX('%[0-9.-]%', @cleaned_string), 
            LEN(@cleaned_string)
        );
        
        -- Try to convert
        IF TRY_CAST(@cleaned_string AS DECIMAL(18,2)) IS NOT NULL
            SET @clean = CAST(@cleaned_string AS DECIMAL(18,2));
    END
    
    RETURN @clean;
END;
GO

-- Test the function
SELECT 
    amount AS dirty_amount,
    dbo.fn_clean_amount(amount) AS clean_amount
FROM ledger_staging;

-- =======================================================================
-- APPROACH 3: Handle during ETL with error logging
-- =======================================================================

CREATE TABLE amount_cleaning_errors (
    error_id INT IDENTITY PRIMARY KEY,
    txn_id INT,
    original_amount VARCHAR(50),
    error_message VARCHAR(255),
    created_at DATETIME2 DEFAULT GETDATE()
);

-- ETL process with error handling
INSERT INTO ledger (txn_id, account_id, txn_time, amount, currency, memo)
SELECT 
    txn_id,
    account_id,
    txn_time,
    dbo.fn_clean_amount(amount) AS amount,
    currency,
    memo
FROM ledger_staging
WHERE dbo.fn_clean_amount(amount) IS NOT NULL;

-- Log records that couldn't be cleaned
INSERT INTO amount_cleaning_errors (txn_id, original_amount, error_message)
SELECT 
    txn_id,
    amount,
    'Could not parse amount to decimal'
FROM ledger_staging
WHERE dbo.fn_clean_amount(amount) IS NULL;

-- =======================================================================
-- APPROACH 4: Using TRY_PARSE for locale-aware parsing
-- =======================================================================

-- For amounts with locale-specific formatting
SELECT 
    amount,
    TRY_PARSE(amount AS DECIMAL(18,2) USING 'en-US') AS us_parsed,
    TRY_PARSE(amount AS DECIMAL(18,2) USING 'de-DE') AS de_parsed  -- Handles comma as decimal
FROM ledger_staging;

/* Summary of Approaches:
   - TRY_CAST: Best for simple cleaning
   - Custom function: Reusable, handles complex patterns
   - Error logging: Production-ready, tracks issues
   - TRY_PARSE: Locale-aware, good for international data
*/
