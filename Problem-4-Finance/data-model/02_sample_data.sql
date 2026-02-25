-- SQL Server (T-SQL)
-- Sample Data for Finance Ledger Exercises

-- Insert sample accounts
INSERT INTO accounts (account_id, name, balance) VALUES
(1, 'Checking Account - John', 5000.00),
(2, 'Savings Account - John', 10000.00),
(3, 'Checking Account - Jane', 7500.00),
(4, 'Business Account - Acme Corp', 25000.00),
(5, 'Investment Account - John', 15000.00);

-- Insert sample ledger entries
INSERT INTO ledger (txn_id, account_id, txn_time, amount, currency, memo) VALUES
(1001, 1, '2025-01-15 09:30:00', -50.00, 'USD', 'ATM Withdrawal'),
(1002, 2, '2025-01-15 09:30:00', 50.00, 'USD', 'Transfer from Checking'),
(1003, 1, '2025-01-20 14:15:00', -25.50, 'USD', 'Coffee Shop'),
(1004, 3, '2025-01-22 11:00:00', -200.00, 'USD', 'Online Purchase'),
(1005, 4, '2025-02-01 08:45:00', -5000.00, 'USD', 'Payroll'),
(1006, 1, '2025-02-05 16:20:00', 1000.00, 'USD', 'Direct Deposit'),
(1007, 5, '2025-02-10 10:30:00', -2000.00, 'USD', 'Stock Purchase'),
(1008, 2, '2025-02-15 13:45:00', 100.00, 'USD', 'Interest Payment');

-- Insert sample staging_accounts (with potential data quality issues)
INSERT INTO staging_accounts (account_id, email, updated_at) VALUES
(1, 'john.doe@email.com', '2025-02-20 10:00:00'),
(2, 'john.savings@email.com', '2025-02-19 09:30:00'),
(3, 'jane.doe@email.com', '2025-02-18 14:15:00'),
-- Duplicate email (different case) - should be handled
(6, 'JOHN.DOE@EMAIL.COM', '2025-02-21 08:00:00'),
-- New account not in dim_customer yet
(7, 'new.customer@email.com', '2025-02-22 11:30:00'),
-- Account with NULL email (should be handled)
(8, NULL, '2025-02-20 16:45:00');

-- Insert sample dim_customer (target dimension)
INSERT INTO dim_customer (customer_id, email, updated_at) VALUES
(101, 'john.doe@email.com', '2025-01-01 00:00:00'),  -- Older timestamp
(102, 'jane.doe@email.com', '2025-01-15 00:00:00'),
(103, 'bob.smith@email.com', '2025-02-01 00:00:00');

PRINT 'Finance sample data inserted successfully';
