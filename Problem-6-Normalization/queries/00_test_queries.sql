-- =======================================================================
-- PROBLEM 6: NORMALIZATION - VIEW ALL TABLES
-- =======================================================================

-- First, let's create some sample data to test the structure
-- (since the original question only asked for the model, not data)

-- =======================================================================
-- PART 1: Insert sample data for testing
-- =======================================================================

-- Insert sample customers
INSERT INTO dim_customer2 (customer_id, email, full_name, membership_date, notes) VALUES
(1, 'john.smith@email.com', 'John Smith', '2023-01-15', 'VIP customer'),
(2, 'jane.doe@email.com', 'Jane Doe', '2023-03-20', NULL),
(3, 'bob.wilson@email.com', 'Bob Wilson', '2024-02-10', 'Prefers email');

-- Insert sample products
INSERT INTO dim_product (product_id, product_number, sku, product_name) VALUES
(101, 'P1001', 'SKU-EL-001', 'Wireless Headphones'),
(102, 'P1002', 'SKU-EL-002', '4K Smart TV'),
(103, 'P1003', 'SKU-BK-001', 'Mystery Novel');

-- Insert sample dates (just a few for testing)
INSERT INTO dim_date (date_key, full_date, year, quarter, month, month_name, day, day_of_week, day_name, is_weekend) VALUES
(20250115, '2025-01-15', 2025, 1, 1, 'January', 15, 3, 'Wednesday', 0),
(20250116, '2025-01-16', 2025, 1, 1, 'January', 16, 4, 'Thursday', 0),
(20250117, '2025-01-17', 2025, 1, 1, 'January', 17, 5, 'Friday', 0);

-- Insert sample orders
INSERT INTO fact_orders (order_number, order_date_key, customer_id, product_id, quantity, price) VALUES
('ORD-001', 20250115, 1, 101, 2, 29.99),
('ORD-001', 20250115, 1, 103, 1, 12.99),
('ORD-002', 20250116, 2, 102, 1, 499.99),
('ORD-003', 20250117, 3, 101, 1, 29.99),
('ORD-003', 20250117, 3, 103, 2, 12.99);

-- =======================================================================
-- PART 2: View each table individually
-- =======================================================================

SELECT '=== DIM_CUSTOMER2 TABLE (Customers stored once) ===' AS section;
SELECT 
    customer_id,
    email,
    full_name,
    membership_date,
    notes,
    created_at
FROM dim_customer2
ORDER BY customer_id;

SELECT '=== DIM_PRODUCT TABLE (Products stored once) ===' AS section;
SELECT 
    product_id,
    product_number,
    sku,
    product_name
FROM dim_product
ORDER BY product_id;

SELECT '=== DIM_DATE TABLE (Date dimension) ===' AS section;
SELECT 
    date_key,
    full_date,
    year,
    quarter,
    month,
    month_name,
    day,
    day_name,
    is_weekend
FROM dim_date
ORDER BY date_key;

SELECT '=== FACT_ORDERS TABLE (Transaction facts) ===' AS section;
SELECT 
    order_number,
    date_key AS order_date_key,
    customer_id,
    product_id,
    quantity,
    price,
    (quantity * price) AS line_total
FROM fact_orders
ORDER BY order_number, product_id;

-- =======================================================================
-- PART 3: Reconstruct the original denormalized view
-- =======================================================================

SELECT '=== RECONSTRUCTED DENORMALIZED VIEW (Original CSV format) ===' AS section;
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
    dc.notes
FROM fact_orders fo
INNER JOIN dim_date d ON fo.order_date_key = d.date_key
INNER JOIN dim_customer2 dc ON fo.customer_id = dc.customer_id
INNER JOIN dim_product dp ON fo.product_id = dp.product_id
ORDER BY fo.order_number, dp.product_number;

-- =======================================================================
-- PART 4: Show relationships (how tables connect)
-- =======================================================================

SELECT '=== TABLE RELATIONSHIPS (Foreign Keys) ===' AS section;
SELECT 
    'fact_orders' AS table_name,
    'customer_id → dim_customer2.customer_id' AS relationship
UNION ALL
SELECT 
    'fact_orders',
    'product_id → dim_product.product_id'
UNION ALL
SELECT 
    'fact_orders',
    'order_date_key → dim_date.date_key';

-- =======================================================================
-- PART 5: Show data distribution
-- =======================================================================

SELECT '=== DATA COUNTS BY TABLE ===' AS section;
SELECT 'dim_customer2' AS table_name, COUNT(*) AS row_count FROM dim_customer2
UNION ALL
SELECT 'dim_product', COUNT(*) FROM dim_product
UNION ALL
SELECT 'dim_date', COUNT(*) FROM dim_date
UNION ALL
SELECT 'fact_orders', COUNT(*) FROM fact_orders;

-- =======================================================================
-- PART 6: Sample analytics queries (showing benefits of normalization)
-- =======================================================================

SELECT '=== ANALYTICS EXAMPLE: Revenue by Customer ===' AS section;
SELECT 
    dc.customer_id,
    dc.full_name,
    COUNT(DISTINCT fo.order_number) AS orders,
    SUM(fo.quantity * fo.price) AS total_spent
FROM fact_orders fo
INNER JOIN dim_customer2 dc ON fo.customer_id = dc.customer_id
GROUP BY dc.customer_id, dc.full_name
ORDER BY total_spent DESC;

SELECT '=== ANALYTICS EXAMPLE: Revenue by Product ===' AS section;
SELECT 
    dp.product_id,
    dp.product_name,
    dp.sku,
    SUM(fo.quantity) AS units_sold,
    SUM(fo.quantity * fo.price) AS revenue
FROM fact_orders fo
INNER JOIN dim_product dp ON fo.product_id = dp.product_id
GROUP BY dp.product_id, dp.product_name, dp.sku
ORDER BY revenue DESC;

SELECT '=== ANALYTICS EXAMPLE: Revenue by Month ===' AS section;
SELECT 
    d.year,
    d.month,
    d.month_name,
    COUNT(DISTINCT fo.order_number) AS orders,
    SUM(fo.quantity * fo.price) AS revenue
FROM fact_orders fo
INNER JOIN dim_date d ON fo.order_date_key = d.date_key
GROUP BY d.year, d.month, d.month_name
ORDER BY d.year, d.month;
