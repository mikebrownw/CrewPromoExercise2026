--View all 4 tables (customers, products, orders, order_items)
SELECT * FROM customers;

SELECT * FROM products;

SELECT * FROM orders
ORDER BY order_id ASC;

SELECT * FROM order_items
ORDER BY order_id ASC;

-- View all customers
SELECT 'customers' AS table_name, * FROM customers;

-- View all products
SELECT 'products' AS table_name, * FROM products;

-- View all orders (sorted)
SELECT 'orders' AS table_name, * FROM orders
ORDER BY order_id ASC;

-- View all order_items (sorted)
SELECT 'order_items' AS table_name, * FROM order_items
ORDER BY order_id ASC;
