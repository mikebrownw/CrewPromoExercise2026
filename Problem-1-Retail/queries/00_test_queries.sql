--View all 4 tables (customers, products, orders, order_items)
SELECT * FROM customers;

SELECT * FROM products;

SELECT * FROM orders
ORDER BY order_id ASC;

SELECT * FROM order_items
ORDER BY order_id ASC;

-------------------------------------------------------------

SELECT '========== CUSTOMERS ==========' AS [Header];
SELECT * FROM customers;

SELECT '========== PRODUCTS ==========' AS [Header];
SELECT * FROM products;

SELECT '========== ORDERS ==========' AS [Header];
SELECT * FROM orders ORDER BY order_id;

SELECT '========== ORDER ITEMS ==========' AS [Header];
SELECT * FROM order_items ORDER BY order_id;
