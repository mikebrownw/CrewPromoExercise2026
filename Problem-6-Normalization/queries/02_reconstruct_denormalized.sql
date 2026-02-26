-- SQL Server (T-SQL)
-- Reconstruct the original denormalized format from normalized tables
-- Useful for reporting or backward compatibility

-- =======================================================================
-- METHOD 1: Using the view (simplest)
-- =======================================================================
SELECT * FROM vw_denormalized_orders
ORDER BY order_number, product_number;

-- =======================================================================
-- METHOD 2: Explicit JOINs with additional derived columns
-- =======================================================================
SELECT 
    fo.order_number,
    d.full_date AS order_date,
    fo.quantity,
    fo.price,
    dp.product_number,
    dp.sku,
    dp.product_name AS product,
    dc.customer_id,
    dc.email,
    dc.full_name AS name,
    dc.membership_date,
    dc.notes,
    -- Add derived columns for analytics
    fo.quantity * fo.price AS line_total,
    d.year,
    d.quarter,
    d.month_name,
    CASE 
        WHEN dc.membership_date IS NOT NULL 
        THEN DATEDIFF(day, dc.membership_date, d.full_date) 
        ELSE NULL 
    END AS days_since_membership
FROM fact_orders fo
INNER JOIN dim_date d ON fo.order_date_key = d.date_key
INNER JOIN dim_customer dc ON fo.customer_id = dc.customer_id
INNER JOIN dim_product dp ON fo.product_id = dp.product_id
ORDER BY fo.order_number, dp.product_number;

-- =======================================================================
-- METHOD 3: Include data quality flags
-- =======================================================================
SELECT 
    fo.order_number,
    d.full_date AS order_date,
    fo.quantity,
    fo.price,
    dp.product_number,
    dp.sku,
    dp.product_name AS product,
    dc.customer_id,
    dc.email,
    dc.full_name AS name,
    dc.membership_date,
    dc.notes,
    -- Data quality flags
    CASE WHEN fo.quantity <= 0 THEN 'Invalid Quantity' ELSE 'OK' END AS quantity_flag,
    CASE WHEN fo.price < 0 THEN 'Invalid Price' ELSE 'OK' END AS price_flag,
    CASE WHEN dc.email IS NULL OR dc.email NOT LIKE '%_@__%.__%' THEN 'Invalid Email' ELSE 'OK' END AS email_flag,
    CASE WHEN dc.membership_date > CAST(GETDATE() AS DATE) THEN 'Future Date' ELSE 'OK' END AS membership_flag
FROM fact_orders fo
INNER JOIN dim_date d ON fo.order_date_key = d.date_key
INNER JOIN dim_customer dc ON fo.customer_id = dc.customer_id
INNER JOIN dim_product dp ON fo.product_id = dp.product_id;

-- =======================================================================
-- METHOD 4: Pivot to show orders with multiple products (original CSV style)
-- =======================================================================
-- This reconstructs what the original CSV might have looked like
-- (one row per order with concatenated products)
SELECT 
    fo.order_number,
    MAX(d.full_date) AS order_date,
    COUNT(*) AS number_of_products,
    SUM(fo.quantity) AS total_quantity,
    SUM(fo.quantity * fo.price) AS order_total,
    MAX(dc.customer_id) AS customer_id,
    MAX(dc.email) AS email,
    MAX(dc.full_name) AS name,
    -- Concatenate all products in the order
    STRING_AGG(dp.product_name + ' (' + CAST(fo.quantity AS VARCHAR) + ')', '; ') AS products_purchased
FROM fact_orders fo
INNER JOIN dim_date d ON fo.order_date_key = d.date_key
INNER JOIN dim_customer dc ON fo.customer_id = dc.customer_id
INNER JOIN dim_product dp ON fo.product_id = dp.product_id
GROUP BY fo.order_number
ORDER BY fo.order_number;

-- =======================================================================
-- VALIDATION: Compare counts with original staging
-- =======================================================================
SELECT 
    'Original Staging Rows' AS source,
    COUNT(*) AS row_count
FROM staging_orders
UNION ALL
SELECT 
    'Reconstructed View Rows',
    COUNT(*)
FROM vw_denormalized_orders
UNION ALL
SELECT 
    'Fact Orders Rows (line items)',
    COUNT(*)
FROM fact_orders;
