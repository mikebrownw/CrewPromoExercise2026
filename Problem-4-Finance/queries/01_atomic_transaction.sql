-- SQL Server (T-SQL)
-- Purpose: Atomic transaction to debit account 1 and credit account 2
-- Ensures rollback on any error (ACID compliance
--Letter	Stands For	Meaning	Bank Transfer Example
--A	Atomicity	All or nothing	If transferring $100 from A to B, both accounts update or neither does
--C	Consistency	Data follows all rules	Can't go negative if rule says balance >= 0
--I	Isolation	Transactions don't interfere	Two transfers happening at same time don't get mixed up
--D	Durability	Once saved, stays saved	Even if power fails, completed transfer is permanent))

PRINT '===== QUERY 1:  Atomic Transactions: Suppose your application needs to debit account 1 by $100 and
credit account 2 by $100, write some sql code to update those accounts; rollback on any
error. =====';

-- First, make sure we have a sequence for transaction IDs
-- (Check if it exists and create if not)
IF NOT EXISTS (SELECT * FROM sys.sequences WHERE name = 'seq_txn_id')
BEGIN
    CREATE SEQUENCE seq_txn_id START WITH 2000 INCREMENT BY 1;
END

-- Create the stored procedure (optional - you can also run the transaction directly)
-- But in DB Fiddle, you might want to just run the transaction directly

-- ====================================================
-- Run the transaction directly
-- ====================================================
BEGIN TRANSACTION;
BEGIN TRY
    -- Check if accounts exist
    IF NOT EXISTS (SELECT 1 FROM accounts WHERE account_id = 1)
        THROW 50001, 'Account 1 not found', 1;
    
    IF NOT EXISTS (SELECT 1 FROM accounts WHERE account_id = 2)
        THROW 50002, 'Account 2 not found', 1;
    
    -- Check sufficient funds
    IF (SELECT balance FROM accounts WHERE account_id = 1) < 100
        THROW 50003, 'Insufficient funds', 1;
    
    -- Debit account 1
    UPDATE accounts 
    SET balance = balance - 100.00
    WHERE account_id = 1;
    
    -- Credit account 2
    UPDATE accounts 
    SET balance = balance + 100.00
    WHERE account_id = 2;
    
    -- Record in ledger
    INSERT INTO ledger (txn_id, account_id, amount, currency, memo)
    VALUES 
        (NEXT VALUE FOR seq_txn_id, 1, -100.00, 'USD', 'Transfer to account 2'),
        (NEXT VALUE FOR seq_txn_id, 2, 100.00, 'USD', 'Transfer from account 1');
    
    COMMIT TRANSACTION;
    SELECT 'Transaction successful' AS result;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    
    SELECT 
        ERROR_NUMBER() AS error_number,
        ERROR_MESSAGE() AS error_message;
END CATCH;
