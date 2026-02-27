-- SQL Server (T-SQL)
-- Purpose: Atomic transaction to debit account 1 and credit account 2
-- Ensures rollback on any error (ACID compliance)

PRINT '===== Atomic Transactions: Suppose your application needs to debit account 1 by $100 and
credit account 2 by $100, write some sql code to update those accounts; rollback on any
error. ====='
    
    BEGIN TRANSACTION;
BEGIN TRY
    -- Debit account 1 (withdraw $100)
    UPDATE accounts 
    SET balance = balance - 100.00
    WHERE account_id = 1;
    
    -- Check if account 1 exists and has sufficient funds
    IF @@ROWCOUNT = 0
        THROW 50001, 'Account 1 not found', 1;
    
    IF (SELECT balance FROM accounts WHERE account_id = 1) < 0
        THROW 50002, 'Insufficient funds in account 1', 1;
    
    -- Credit account 2 (deposit $100)
    UPDATE accounts 
    SET balance = balance + 100.00
    WHERE account_id = 2;
    
    IF @@ROWCOUNT = 0
        THROW 50003, 'Account 2 not found', 1;
    
    -- Record the transaction in ledger
    INSERT INTO ledger (txn_id, account_id, txn_time, amount, currency, memo)
    VALUES 
        (NEXT VALUE FOR seq_txn_id, 1, GETDATE(), -100.00, 'USD', 'Transfer to account 2'),
        (NEXT VALUE FOR seq_txn_id, 2, GETDATE(), 100.00, 'USD', 'Transfer from account 1');
    
    -- If we got here, commit the transaction
    COMMIT TRANSACTION;
    PRINT 'Transaction completed successfully';
END TRY
BEGIN CATCH
    -- Rollback on any error
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    
    -- Re-throw the error
    THROW;
END CATCH;
GO
