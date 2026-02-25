-- SQL Server (T-SQL)
-- Complete Data Model for Finance Ledger

-- Create accounts table
CREATE TABLE accounts (
    account_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    balance DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    -- Add constraint to prevent negative balances (optional business rule)
    CONSTRAINT chk_balance_non_negative CHECK (balance >= 0)
);

-- Create ledger table for transaction history
CREATE TABLE ledger (
    txn_id INT PRIMARY KEY,
    account_id INT NOT NULL,
    txn_time DATETIME2 NOT NULL DEFAULT GETDATE(),
    amount DECIMAL(18,2) NOT NULL,
    currency VARCHAR(3) NOT NULL DEFAULT 'USD',
    memo NVARCHAR(255),
    FOREIGN KEY (account_id) REFERENCES accounts(account_id)
);

-- Create staging_accounts (source data that may be dirty)
CREATE TABLE staging_accounts (
    account_id INT PRIMARY KEY,
    email VARCHAR(100),
    updated_at DATETIME2
);

-- Create dim_customer (target dimension table)
CREATE TABLE dim_customer (
    customer_id INT PRIMARY KEY,
    email VARCHAR(100) UNIQUE NOT NULL,
    updated_at DATETIME2
);

-- Create indexes for performance
CREATE INDEX idx_ledger_account_time ON ledger(account_id, txn_time);
CREATE INDEX idx_staging_updated ON staging_accounts(updated_at);
CREATE INDEX idx_dim_customer_email ON dim_customer(email);

PRINT 'Finance tables created successfully';
