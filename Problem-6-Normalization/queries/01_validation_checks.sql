-- SQL Server (T-SQL)
-- Validation queries to check data quality and constraints

-- =======================================================================
-- CHECK 1: Verify all constraints are working
-- =======================================================================

-- Test CHECK constraint: quantity > 0
-- This should fail if you try to insert invalid data
BEGIN TRY
    INSERT INTO fact_orders (order_number, order_date_key, customer_id, product_id, quantity, price)
    VALUES ('TEST-001', 20250101, 1001, 1001, 0, 10.00);
    PRINT 'ERROR: Should have failed quantity > 0 check';
END TRY
BEGIN CATCH
    PRINT 'PASS: Quantity > 0 check working: ' + ERROR_MESSAGE();
END CATCH;

-- Test CHECK constraint: price >= 0
BEGIN TRY
    INSERT INTO fact_orders (order_number, order_date_key, customer_id, product_id, quantity, price)
    VALUES ('TEST-002', 20250101, 1001, 1001, 1, -5.00);
    PRINT 'ERROR: Should have failed price >= 0 check';
END TRY
BEGIN CATCH
    PRINT 'PASS: Price >= 0 check working: ' + ERROR_MESSAGE();
END CATCH;

-- =======================================================================
-- CHECK 2: Verify foreign key integrity
-- =======================================================================

-- Check for orphaned records (should return 0)
SELECT 
    'Orphaned Orders' AS check_name,
    COUNT(*) AS count
FROM fact_orders f
WHERE NOT EXISTS (SELECT 1 FROM dim_customer c WHERE c.customer_id = f.customer_id)
   OR NOT EXISTS (SELECT 1 FROM dim_product p WHERE p.product_id = f.product_id)
   OR NOT EXISTS (SELECT 1 FROM dim_date d WHERE d.date_key = f.order_date_key);

-- =======================================================================
-- CHECK 3: Verify unique constraints
-- =======================================================================

-- Check for duplicate emails in customer dimension (should return 0)
SELECT 
    email,
    COUNT(*) AS duplicate_count
FROM dim_customer
GROUP BY email
HAVING COUNT(*) > 1;

-- Check for duplicate SKUs in product dimension (should return 0)
SELECT 
    sku,
    COUNT(*) AS duplicate_count
FROM dim_product
GROUP BY sku
HAVING COUNT(*) > 1;

-- =======================================================================
-- CHECK 4: Data completeness
-- =======================================================================

-- Check for NULLs in required fields
SELECT 
    'Orders missing customer' AS check_name,
    COUNT(*) AS count
FROM fact_orders
WHERE customer_id IS NULL
UNION ALL
SELECT 
    'Orders missing product',
    COUNT(*)
FROM fact_orders
WHERE product_id IS NULL
UNION ALL
SELECT 
    'Orders missing date',
    COUNT(*)
FROM fact_orders
WHERE order_date_key IS NULL;

-- =======================================================================
-- CHECK 5: Business rule validation
-- =======================================================================

-- Customers with membership date in the future
SELECT 
    customer_id,
    email,
    membership_date
FROM dim_customer
WHERE membership_date > CAST(GETDATE() AS DATE);

-- Orders with unusually high quantities (potential data entry errors)
SELECT 
    order_number,
    quantity,
    price
FROM fact_orders
WHERE quantity > 1000 OR price > 100000;

-- =======================================================================
-- CHECK 6: Referential integrity report
-- =======================================================================

SELECT 
    'Customer Count' AS metric,
    COUNT(*) AS value
FROM dim_customer
UNION ALL
SELECT 
    'Product Count',
    COUNT(*)
FROM dim_product
UNION ALL
SELECT 
    'Order Line Count',
    COUNT(*)
FROM fact_orders
UNION ALL
SELECT 
    'Date Range (Years)',
    COUNT(DISTINCT year)
FROM dim_date;
