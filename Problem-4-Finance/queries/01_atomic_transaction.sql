-- SQL Server (T-SQL)
-- Purpose: Atomic transaction to debit account 1 and credit account 2
-- Ensures rollback on any error (ACID compliance)

-- Method 1: Basic transaction with explicit error handling
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

-- Method 2: More robust with SAVEPOINT and XACT_ABORT
SET XACT_ABORT ON;  -- Automatically rollback on any error

BEGIN TRANSACTION;
    -- Savepoint allows partial rollback if needed
    SAVE TRANSACTION BeforeTransfer;
    
    -- Debit account 1
    UPDATE accounts 
    SET balance = balance - 100.00
    WHERE account_id = 1;
    
    -- Verify the update worked
    IF @@ROWCOUNT = 0
    BEGIN
        ROLLBACK TRANSACTION BeforeTransfer;
        THROW 50001, 'Account 1 not found', 1;
    END
    
    -- Credit account 2
    UPDATE accounts 
    SET balance = balance + 100.00
    WHERE account_id = 2;
    
    IF @@ROWCOUNT = 0
    BEGIN
        ROLLBACK TRANSACTION BeforeTransfer;
        THROW 50002, 'Account 2 not found', 1;
    END
    
    -- Insert ledger entries
    INSERT INTO ledger (txn_id, account_id, amount, currency, memo)
    SELECT 
        ISNULL(MAX(txn_id), 0) + 1, 1, -100.00, 'USD', 'Transfer to account 2'
    FROM ledger;
    
    INSERT INTO ledger (txn_id, account_id, amount, currency, memo)
    SELECT 
        ISNULL(MAX(txn_id), 0) + 1, 2, 100.00, 'USD', 'Transfer from account 1'
    FROM ledger;
    
COMMIT TRANSACTION;
GO

-- Method 3: Using a sequence for txn_id (recommended for production)
CREATE SEQUENCE seq_txn_id START WITH 2000 INCREMENT BY 1;

CREATE OR ALTER PROCEDURE sp_transfer_funds
    @FromAccount INT,
    @ToAccount INT,
    @Amount DECIMAL(18,2),
    @Currency VARCHAR(3) = 'USD'
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Validate accounts exist and have sufficient funds
        IF NOT EXISTS (SELECT 1 FROM accounts WHERE account_id = @FromAccount)
            THROW 50001, 'Source account not found', 1;
        
        IF NOT EXISTS (SELECT 1 FROM accounts WHERE account_id = @ToAccount)
            THROW 50002, 'Destination account not found', 1;
        
        IF (SELECT balance FROM accounts WHERE account_id = @FromAccount) < @Amount
            THROW 50003, 'Insufficient funds', 1;
        
        -- Perform the transfer
        UPDATE accounts SET balance = balance - @Amount WHERE account_id = @FromAccount;
        UPDATE accounts SET balance = balance + @Amount WHERE account_id = @ToAccount;
        
        -- Record both sides of the transaction
        INSERT INTO ledger (txn_id, account_id, txn_time, amount, currency, memo)
        VALUES 
            (NEXT VALUE FOR seq_txn_id, @FromAccount, GETDATE(), -@Amount, @Currency, 
             CONCAT('Transfer to account ', @ToAccount)),
            (NEXT VALUE FOR seq_txn_id, @ToAccount, GETDATE(), @Amount, @Currency, 
             CONCAT('Transfer from account ', @FromAccount));
        
        COMMIT TRANSACTION;
        
        -- Return success
        SELECT 'Success' AS Status, @Amount AS Amount, @FromAccount AS FromAccount, @ToAccount AS ToAccount;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        -- Return error
        SELECT 
            'Error' AS Status,
            ERROR_NUMBER() AS ErrorNumber,
            ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END;
GO

-- Test the procedure
EXEC sp_transfer_funds @FromAccount = 1, @ToAccount = 2, @Amount = 100.00;
EXEC sp_transfer_funds @FromAccount = 1, @ToAccount = 999, @Amount = 100.00;  -- Should fail

/* ACID Compliance Explained:
   - Atomicity: All or nothing (wrapped in TRANSACTION)
   - Consistency: Constraints (CHECK, FK) ensure data integrity
   - Isolation: Transactions are isolated from each other
   - Durability: Once committed, data persists
*/
