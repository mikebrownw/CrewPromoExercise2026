# Problem 4: Finance (Ledger, ACID, Upserts, Normalization)

## Schema
- accounts(account_id PK, name, balance NUMERIC(18,2))
- ledger(txn_id PK, account_id FK, txn_time TIMESTAMP, amount NUMERIC(18,2), currency, memo)
- staging_accounts(account_id, email, updated_at)
- dim_customer(customer_id PK, email UNIQUE, updated_at)

## Questions
1. Atomic Transactions: Write SQL to debit account 1 by $100 and credit account 2 by $100; rollback on any error.
2. Assume ledger.amount can be text in some source, how would you handle that data in a safe manner to ensure it's an amount?
3. Show SQL to Upsert staging_accounts into dim_customer (newer updated_at wins) and insert any new records.
4. Bonus: How would you tweak to handle deletes if staging_accounts was a full dataset of all current accounts?

## SQL Dialect
All solutions written in SQL Server/T-SQL (SSMS 17 compatible) with transaction handling.
