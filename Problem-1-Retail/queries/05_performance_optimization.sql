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
-- PARTITIONING EXPLANATION (Concept only - for discussion)
-- =======================================================================

/*
Partitioning splits a large table into smaller pieces based on a column (like date).

EXAMPLE CONCEPT (not executable in DB Fiddle):

Instead of one huge table:
    orders (10 million rows)

You split into yearly partitions:
    Partition 1: orders_2023 (2 million rows)
    Partition 2: orders_2024 (3 million rows)  
    Partition 3: orders_2025 (4 million rows)
    Partition 4: orders_2026 (1 million rows)

BENEFITS:
- Queries only scan relevant partition(s), not entire table
- Easier to archive old data (drop entire partition)
- Faster maintenance (rebuild indexes per partition)

FOR YOUR QUERY:
    SELECT * FROM orders WHERE order_date >= '2025-01-01'
    
Without partition: scans all 10M rows
With partition: scans only 2025 partition (4M rows) - 60% faster!

IN REAL SQL SERVER, the syntax would be:

-- Create partition function (defines boundaries)
CREATE PARTITION FUNCTION pf_order_date (DATE)
AS RANGE RIGHT FOR VALUES ('2023-01-01', '2024-01-01', '2025-01-01', '2026-01-01');

-- Create partition scheme (maps to filegroups)
CREATE PARTITION SCHEME ps_order_date
AS PARTITION pf_order_date
TO (FG2023, FG2024, FG2025, FG2026, FG_FUTURE);

-- Create partitioned table
CREATE TABLE orders_partitioned (
    order_id INT,
    order_date DATE,
    customer_id INT,
    status VARCHAR(20),
    total_amount DECIMAL(10,2)
) ON ps_order_date(order_date);
*/

-- Since DB Fiddle doesn't support partitioning,
-- here's a query to show how partitioning would help:
SELECT 
    YEAR(order_date) AS year,
    COUNT(*) AS row_count,
    'Would be in separate partition' AS partition_benefit
FROM orders
GROUP BY YEAR(order_date)
ORDER BY year;

-- =======================================================================
-- PART 4: MATERIALIZED CTE (view alternative) FOR MONTHLY REVENUE
-- =======================================================================

WITH monthly_revenue AS (
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
        p.category
)
-- This SELECT is part of the same statement, not inside the CTE
SELECT * 
FROM monthly_revenue
WHERE month_start >= '2025-01-01' 
  AND month_start < '2026-01-01'
ORDER BY total_revenue DESC;
