-- SQL Server (T-SQL)
-- Purpose: Discuss indexes, partitions, and performance optimization strategies
-- Question 5: What indexes/partitions would you propose to speed up common filters 
-- (status, order_date, customer_id); discuss SARGability and materialized view(s) for monthly revenue.

-- =======================================================================
-- PART 1: RECOMMENDED INDEXES
-- =======================================================================

/*
Based on the common query patterns in Problem 1, here are the optimal indexes:
*/

-- 1. Composite index for order status + date (most frequent filter)
CREATE NONCLUSTERED INDEX idx_orders_status_date 
ON orders(status, order_date) 
INCLUDE (customer_id, total_amount);
/*
Why this index:
- Supports WHERE status = 'completed' AND order_date BETWEEN '2025-01-01' AND '2025-12-31'
- INCLUDE clause adds columns without increasing index size much
- Covering index means SQL Server doesn't need to read the table at all
*/

-- 2. Index for customer history lookups (joins to customers)
CREATE NONCLUSTERED INDEX idx_orders_customer_date 
ON orders(customer_id, order_date DESC) 
INCLUDE (status, total_amount);
/*
Why:
- Optimizes "recent orders by customer" queries
- DESC order matches typical "latest first" requirements
- Used in joins between orders and customers
*/

-- 3. Index for order_items joins and aggregations
CREATE NONCLUSTERED INDEX idx_order_items_product 
ON order_items(product_id) 
INCLUDE (qty, price);
/*
Why:
- Speeds up category/product revenue aggregations
- Covering index prevents key lookups to base table
- Critical for queries that SUM(qty * price) GROUP BY product/category
*/

-- 4. Composite index for category analysis (if you add category to order_items)
-- Note: In current schema, category is only in products table
CREATE NONCLUSTERED INDEX idx_products_category 
ON products(category) 
INCLUDE (product_id, name);

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

/*
SQL Server uses Indexed Views (similar to materialized views in other databases)
This pre-aggregates monthly revenue for instant reporting
*/

-- Step 1: Create view with SCHEMABINDING (required for indexed views)
CREATE VIEW vw_monthly_revenue
WITH SCHEMABINDING
AS
SELECT 
    -- Date bucket for monthly grouping
    DATEFROMPARTS(YEAR(o.order_date), MONTH(o.order_date), 1) AS month_start,
    p.category,
    COUNT_BIG(*) AS transaction_count,        -- Required for indexed views
    COUNT_BIG(DISTINCT o.order_id) AS order_count,
    SUM(oi.qty * oi.price) AS total_revenue,
    SUM(oi.qty) AS total_quantity_sold
FROM dbo.orders o                             -- Must use two-part name
INNER JOIN dbo.order_items oi ON o.order_id = oi.order_id
INNER JOIN dbo.products p ON oi.product_id = p.product_id
WHERE o.status = 'completed'
GROUP BY 
    DATEFROMPARTS(YEAR(o.order_date), MONTH(o.order_date), 1),
    p.category;
GO

-- Step 2: Create unique clustered index to materialize the view
-- This physically stores the aggregated data
CREATE UNIQUE CLUSTERED INDEX IX_vw_monthly_revenue 
ON vw_monthly_revenue (month_start, category);
GO

-- Step 3: Add non-clustered indexes for different query patterns
CREATE NONCLUSTERED INDEX IX_vw_monthly_revenue_category 
ON vw_monthly_revenue (category, month_start) 
INCLUDE (total_revenue);
GO

/*
Benefits of Indexed View:
- Data pre-aggregated and stored physically
- Queries against this view are instantaneous
- Automatically maintained by SQL Server on data changes
- Perfect for dashboards and recurring reports

Example query using the materialized view:
*/
SELECT 
    category,
    SUM(total_revenue) AS revenue_2025
FROM vw_monthly_revenue WITH (NOEXPAND)  -- Hint to use indexed view directly
WHERE month_start >= '2025-01-01' 
  AND month_start < '2026-01-01'
GROUP BY category
HAVING SUM(total_revenue) >= 1000000;

-- =======================================================================
-- PART 5: COMPREHENSIVE INDEXING STRATEGY SUMMARY
-- =======================================================================

/*
┌─────────────────┬──────────────────────────────┬─────────────────────────────┐
│ Table           │ Index                        │ Purpose                     │
├─────────────────┼──────────────────────────────┼─────────────────────────────┤
│ orders          │ PK (order_id)                 │ Uniqueness, lookups         │
│ orders          │ idx_orders_status_date        │ Status + date filtering     │
│ orders          │ idx_orders_customer_date      │ Customer history            │
│ order_items     │ PK (order_id, product_id)     │ Uniqueness                  │
│ order_items     │ idx_order_items_product       │ Product aggregations        │
│ products        │ PK (product_id)                │ Uniqueness                  │
│ products        │ idx_products_category         │ Category analysis           │
│ customers       │ PK (customer_id)               │ Uniqueness                  │
├─────────────────┼──────────────────────────────┼─────────────────────────────┤
│ Materialized    │ IX_vw_monthly_revenue         │ Monthly revenue pre-aggreg. │
└─────────────────┴──────────────────────────────┴─────────────────────────────┘

Estimated Performance Improvements:
- Simple SELECT with indexes: 10-50x faster
- Aggregations with covering indexes: 5-20x faster
- Partitioned tables: 2-10x faster for range scans
- Materialized views: 100-1000x faster for pre-aggregated queries

Storage Overhead Estimate (for 10M orders):
- Base tables: ~2-3 GB
- Indexes: additional 1-2 GB
- Materialized view: ~100-200 MB
- Total: ~3-5 GB vs 2-3 GB without indexes
*/
