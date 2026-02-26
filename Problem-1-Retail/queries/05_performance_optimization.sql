-- SQL Server (T-SQL)
-- Purpose: Discuss indexes, partitions, and performance optimization strategies
-- Question 5: What indexes/partitions would you propose to speed up common filters 
-- (status, order_date, customer_id); discuss SARGability and materialized view(s) for monthly revenue.

-- =======================================================================
-- PART 1: RECOMMENDED INDEXES (with safety checks)
-- =======================================================================

/*
Based on the common query patterns in Problem 1, here are the optimal indexes:
*/

-- Show all indexes on your tables
SELECT 
    OBJECT_NAME(object_id) AS table_name,
    name AS index_name,
    type_desc
FROM sys.indexes
WHERE OBJECT_NAME(object_id) IN ('orders', 'order_items', 'products', 'customers')
    AND name IS NOT NULL;

--Indexes created in 01_create_tables:
-- Speeds up: WHERE status = 'completed' AND order_date BETWEEN '2025-01-01' AND '2025-12-31'
CREATE INDEX idx_orders_status_date ON orders(status, order_date) INCLUDE (customer_id, total_amount);

-- Speeds up: JOIN customers ON orders.customer_id = customer_id
CREATE INDEX idx_orders_customer ON orders(customer_id) INCLUDE (order_date, status, total_amount);

-- Speeds up: SUM(qty * price) GROUP BY category (for revenue queries)
CREATE INDEX idx_order_items_product ON order_items(product_id) INCLUDE (qty, price);

-- =======================================================================
-- PART 2: SARGABILITY DISCUSSION
-- =======================================================================

/*
SARGable = Search ARGument-able - ability to use an index effectively

SARGable patterns (use indexes):
- o.order_date >= '2025-01-01'                 -- Index can seek
- o.status = 'completed'                        -- Exact match
- o.customer_id = 1001                          -- Equality
- o.order_date BETWEEN '2025-01-01' AND '2025-12-31'  -- Range seek

Non-SARGable patterns (avoid - full table scan):
- YEAR(o.order_date) = 2025                     -- Function on column
- CONVERT(VARCHAR, o.order_date, 101) = '01/01/2025'  -- Conversion
- o.status LIKE '%complete%'                     -- Leading wildcard
- o.total_amount + 10 > 100                      -- Arithmetic on column
- ISNULL(o.status, 'pending') = 'completed'      -- Function on column

Example of fixing non-SARGable queries:
-- BAD (full table scan):
SELECT * FROM orders WHERE YEAR(order_date) = 2025;

-- GOOD (uses index):
SELECT * FROM orders 
WHERE order_date >= '2025-01-01' 
  AND order_date < '2026-01-01';
*/

-- =======================================================================
-- PART 3: PARTITIONING STRATEGY
-- =======================================================================

/*
For tables with millions of rows, partitioning by date improves performance:

1. Create partition function (by year or month)
*/
CREATE PARTITION FUNCTION pf_order_date (DATE)
AS RANGE RIGHT FOR VALUES (
    '2023-01-01', '2024-01-01', '2025-01-01', '2026-01-01'
);
GO

/*
2. Create partition scheme mapping to filegroups
   (Assumes filegroups FG2023, FG2024, FG2025, FG2026, FG_FUTURE exist)
*/
CREATE PARTITION SCHEME ps_order_date
AS PARTITION pf_order_date
TO (FG2023, FG2024, FG2025, FG2026, FG_FUTURE);
GO

/*
3. Create partitioned table (or alter existing)
*/
-- Option A: Create new partitioned table
CREATE TABLE orders_partitioned (
    order_id INT NOT NULL,
    order_date DATETIME2 NOT NULL,
    customer_id INT NOT NULL,
    status VARCHAR(20),
    total_amount DECIMAL(10,2),
    CONSTRAINT PK_orders_partitioned PRIMARY KEY (order_id, order_date)  -- Partition key in PK
) ON ps_order_date(order_date);
GO

-- Option B: Partition existing table (SQL Server 2016+)
-- ALTER TABLE orders DROP CONSTRAINT PK_orders;
-- CREATE CLUSTERED INDEX IX_orders_date ON orders(order_date) ON ps_order_date(order_date);

/*
Benefits of partitioning by order_date:
- Partition elimination: queries only scan relevant year(s)
  e.g., WHERE order_date >= '2025-01-01' only scans 2025 partition
- Easier data archival: can switch out old partitions
- Parallel scanning: can scan partitions simultaneously
- Improved maintenance: rebuild indexes per partition
*/

-- =======================================================================
-- PART 4: MATERIALIZED VIEW FOR MONTHLY REVENUE
-- =======================================================================

-- SQL Server (T-SQL) - DB Fiddle Compatible Version
-- Regular View for monthly revenue (works in DB Fiddle)

-- Create the view
CREATE VIEW vw_monthly_revenue
AS
SELECT 
    DATEFROMPARTS(YEAR(o.order_date), MONTH(o.order_date), 1) AS month_start,
    p.category,
    COUNT(*) AS transaction_count,
    COUNT(DISTINCT o.order_id) AS order_count,
    SUM(oi.qty * oi.price) AS total_revenue,
    SUM(oi.qty) AS total_quantity_sold
FROM orders o
INNER JOIN order_items oi ON o.order_id = oi.order_id
INNER JOIN products p ON oi.product_id = p.product_id
WHERE o.status = 'completed'
GROUP BY 
    DATEFROMPARTS(YEAR(o.order_date), MONTH(o.order_date), 1),
    p.category;

-- Test the view (run this separately)
SELECT * FROM vw_monthly_revenue 
WHERE month_start >= '2025-01-01' 
  AND month_start < '2026-01-01'
ORDER BY month_start, category;
