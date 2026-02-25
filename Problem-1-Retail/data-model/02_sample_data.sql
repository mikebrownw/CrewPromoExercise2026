-- SQL Server (T-SQL)
-- Sample Data for Retail Analytics Exercise
-- Using https://www.mockaroo.com/ style realistic data

-- Insert sample customers
INSERT INTO customers (customer_id, first_name, last_name, email, region, created_at) VALUES
(1001, 'John', 'Smith', 'john.smith@email.com', 'Northeast', '2023-05-15'),
(1002, 'Sarah', 'Johnson', 'sarah.j@email.com', 'West', '2023-08-22'),
(1003, 'Michael', 'Williams', 'mwilliams@email.com', 'South', '2024-01-10'),
(1004, 'Emily', 'Brown', 'emily.brown@email.com', 'Midwest', '2024-03-05'),
(1005, 'David', 'Jones', 'djones@email.com', 'Northeast', '2024-06-18'),
(1006, 'Jessica', 'Garcia', 'jgarcia@email.com', 'West', '2024-09-12'),
(1007, 'Robert', 'Miller', 'rmiller@email.com', 'South', '2024-11-30'),
(1008, 'Jennifer', 'Davis', 'jdavis@email.com', 'Midwest', '2025-01-25'),
(1009, 'William', 'Rodriguez', 'wrodriguez@email.com', 'Northeast', '2025-02-14'),
(1010, 'Maria', 'Martinez', 'mmartinez@email.com', 'West', '2025-03-20');

-- Insert sample products
INSERT INTO products (product_id, category, sku, name) VALUES
(5001, 'Electronics', 'SKU-EL-001', 'Wireless Headphones'),
(5002, 'Electronics', 'SKU-EL-002', '4K Smart TV - 55"'),
(5003, 'Electronics', 'SKU-EL-003', 'Laptop Pro 15"'),
(5004, 'Clothing', 'SKU-CL-001', 'Men''s Casual Jacket'),
(5005, 'Clothing', 'SKU-CL-002', 'Women''s Running Shoes'),
(5006, 'Clothing', 'SKU-CL-003', 'Designer Jeans'),
(5007, 'Home & Garden', 'SKU-HG-001', 'Coffee Maker Deluxe'),
(5008, 'Home & Garden', 'SKU-HG-002', 'Bedding Set - Queen'),
(5009, 'Home & Garden', 'SKU-HG-003', 'Indoor Plant Collection'),
(5010, 'Sports', 'SKU-SP-001', 'Yoga Mat Premium'),
(5011, 'Sports', 'SKU-SP-002', 'Dumbbell Set 20lbs'),
(5012, 'Sports', 'SKU-SP-003', 'Bicycle Helmet'),
(5013, 'Books', 'SKU-BK-001', 'The Great Novel'),
(5014, 'Books', 'SKU-BK-002', 'Cookbook Collection'),
(5015, 'Books', 'SKU-BK-003', 'Children''s Storybook Set');

-- Insert sample orders (mix of 2025 and earlier)
INSERT INTO orders (order_id, order_date, customer_id, status, total_amount) VALUES
-- 2024 orders (for testing date filtering)
(20001, '2024-11-15 10:30:00', 1001, 'completed', 299.99),
(20002, '2024-12-03 14:45:00', 1003, 'completed', 549.50),
(20003, '2024-12-18 09:15:00', 1005, 'completed', 129.99),

-- January 2025 orders
(20004, '2025-01-05 11:20:00', 1002, 'completed', 879.25),
(20005, '2025-01-12 16:30:00', 1004, 'completed', 142.50),
(20006, '2025-01-18 13:10:00', 1006, 'cancelled', 299.99),
(20007, '2025-01-22 10:45:00', 1008, 'completed', 1249.99),
(20008, '2025-01-28 15:20:00', 1010, 'completed', 79.99),

-- February 2025 orders
(20009, '2025-02-02 12:15:00', 1001, 'completed', 429.50),
(20010, '2025-02-08 09:30:00', 1003, 'completed', 189.99),
(20011, '2025-02-14 18:45:00', 1005, 'completed', 259.99),
(20012, '2025-02-20 11:00:00', 1007, 'pending', 89.99),
(20013, '2025-02-25 14:30:00', 1009, 'completed', 699.99),

-- March 2025 orders
(20014, '2025-03-03 10:15:00', 1002, 'completed', 329.50),
(20015, '2025-03-08 13:40:00', 1004, 'completed', 1899.99),
(20016, '2025-03-12 16:20:00', 1006, 'completed', 79.99),
(20017, '2025-03-18 09:55:00', 1008, 'completed', 449.99),
(20018, '2025-03-22 12:10:00', 1010, 'refunded', 129.99),
(20019, '2025-03-27 15:45:00', 1001, 'completed', 239.99),
(20020, '2025-03-30 11:30:00', 1003, 'completed', 519.50),

-- April 2025 orders
(20021, '2025-04-02 14:20:00', 1005, 'completed', 89.99),
(20022, '2025-04-07 10:00:00', 1007, 'completed', 429.99),
(20023, '2025-04-11 13:15:00', 1009, 'completed', 159.50),
(20024, '2025-04-16 17:30:00', 1002, 'completed', 789.99),
(20025, '2025-04-20 09:45:00', 1004, 'completed', 299.99),
(20026, '2025-04-24 12:55:00', 1006, 'completed', 1099.99),
(20027, '2025-04-28 15:10:00', 1008, 'completed', 189.99),

-- May 2025 orders
(20028, '2025-05-01 10:25:00', 1010, 'completed', 79.99),
(20029, '2025-05-05 13:50:00', 1001, 'completed', 349.99),
(20030, '2025-05-09 16:15:00', 1003, 'completed', 629.50),
(20031, '2025-05-13 11:40:00', 1005, 'pending', 219.99),
(20032, '2025-05-17 14:05:00', 1007, 'completed', 159.99),
(20033, '2025-05-21 09:30:00', 1009, 'completed', 499.99),
(20034, '2025-05-25 12:55:00', 1002, 'completed', 899.99),
(20035, '2025-05-29 15:20:00', 1004, 'completed', 69.99),

-- June 2025 orders
(20036, '2025-06-02 10:45:00', 1006, 'completed', 379.50),
(20037, '2025-06-06 13:10:00', 1008, 'completed', 1299.99),
(20038, '2025-06-10 16:35:00', 1010, 'completed', 189.99),
(20039, '2025-06-14 12:00:00', 1001, 'completed', 529.99),
(20040, '2025-06-18 15:25:00', 1003, 'completed', 79.99),
(20041, '2025-06-22 09:50:00', 1005, 'completed', 449.50),
(20042, '2025-06-26 14:15:00', 1007, 'completed', 289.99),
(20043, '2025-06-30 17:40:00', 1009, 'cancelled', 159.99);

-- Insert sample order items
INSERT INTO order_items (order_id, product_id, qty, price) VALUES
-- Order 20004 items
(20004, 5002, 1, 799.99),
(20004, 5001, 1, 79.26),

-- Order 20005 items
(20005, 5004, 1, 89.99),
(20005, 5006, 1, 52.51),

-- Order 20007 items
(20007, 5003, 1, 1249.99),

-- Order 20008 items
(20008, 5001, 1, 79.99),

-- Order 20009 items
(20009, 5007, 1, 129.50),
(20009, 5010, 2, 150.00), -- 2 yoga mats at $75 each

-- Order 20010 items
(20010, 5005, 1, 89.99),
(20010, 5012, 1, 100.00),

-- Order 20011 items
(20011, 5006, 2, 129.98), -- 2 pairs at $64.99 each
(20011, 5004, 1, 130.01),

-- Order 20013 items
(20013, 5002, 1, 699.99),

-- Order 20014 items
(20014, 5009, 3, 149.97), -- 3 plants at $49.99 each
(20014, 5007, 1, 129.50),
(20014, 5008, 1, 50.03),

-- Order 20015 items
(20015, 5003, 1, 1299.99),
(20015, 5002, 1, 600.00),

-- Order 20016 items
(20016, 5001, 1, 79.99),

-- Order 20017 items
(20017, 5011, 1, 149.99),
(20017, 5012, 1, 100.00),
(20017, 5010, 2, 200.00), -- 2 yoga mats

-- Order 20019 items
(20019, 5005, 2, 179.98), -- 2 pairs at $89.99 each
(20019, 5004, 1, 60.01),

-- Order 20020 items
(20020, 5008, 2, 399.98), -- 2 sets at $199.99 each
(20020, 5009, 2, 79.98), -- 2 plants at $39.99 each
(20020, 5007, 1, 39.54),

-- Order 20022 items
(20022, 5013, 3, 89.97), -- 3 books at $29.99 each
(20022, 5014, 2, 159.98), -- 2 cookbooks at $79.99 each
(20022, 5015, 3, 180.04), -- 3 kids books at $60.01 each

-- Order 20024 items
(20024, 5002, 1, 789.99),

-- Order 20026 items
(20026, 5003, 1, 1099.99),

-- Order 20029 items
(20029, 5006, 3, 194.97), -- 3 pairs at $64.99 each
(20029, 5004, 1, 89.99),
(20029, 5005, 1, 65.03),

-- Order 20030 items
(20030, 5002, 1, 629.50),

-- Order 20033 items
(20033, 5007, 2, 259.98), -- 2 coffee makers at $129.99 each
(20033, 5008, 1, 199.99),
(20033, 5009, 1, 40.02),

-- Order 20034 items
(20034, 5003, 1, 899.99),

-- Order 20036 items
(20036, 5011, 2, 299.98), -- 2 dumbbell sets
(20036, 5010, 1, 79.52),

-- Order 20037 items
(20037, 5002, 1, 999.99),
(20037, 5001, 2, 300.00), -- 2 headphones

-- Order 20039 items
(20039, 5006, 3, 224.97), -- 3 pairs at $74.99 each
(20039, 5004, 2, 179.98), -- 2 jackets
(20039, 5005, 2, 125.04), -- 2 running shoes

-- Order 20041 items
(20041, 5008, 1, 199.99),
(20041, 5007, 2, 249.51); -- 2 coffee makers

PRINT 'Sample data inserted successfully';
