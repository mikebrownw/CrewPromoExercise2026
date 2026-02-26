-- SQL Server (T-SQL)
-- Simulate denormalized CSV data as a staging table
-- This represents what you'd load directly from the CSV

CREATE TABLE staging_orders (
    order_number VARCHAR(50),
    order_date DATE,
    quantity INT,
    price DECIMAL(18,2),
    product_number VARCHAR(50),
    sku VARCHAR(50),
    product VARCHAR(200),
    customer_id INT,
    email VARCHAR(100),
    name VARCHAR(100),
    membership_date DATE,
    notes NVARCHAR(MAX)
);

-- Insert sample denormalized data (including quality issues for testing)
INSERT INTO staging_orders VALUES
-- Clean data
('ORD-001', '2025-01-15', 2, 29.99, 'P1001', 'SKU-EL-001', 'Wireless Headphones', 1001, 'john@email.com', 'John Smith', '2023-05-15', 'First time buyer'),
('ORD-001', '2025-01-15', 1, 799.99, 'P1002', 'SKU-EL-002', '4K Smart TV', 1001, 'john@email.com', 'John Smith', '2023-05-15', NULL),
('ORD-002', '2025-01-16', 3, 12.99, 'P1003', 'SKU-BK-001', 'Mystery Novel', 1002, 'jane@email.com', 'Jane Doe', '2024-01-10', 'Gift wrap'),
('ORD-003', '2025-01-17', 1, 45.50, 'P1004', 'SKU-HG-001', 'Coffee Maker', 1003, 'bob@email.com', 'Bob Wilson', '2024-02-20', NULL),

-- Duplicate customer (same customer_id but different email/name - data quality issue)
('ORD-004', '2025-01-18', 2, 89.99, 'P1005', 'SKU-CL-001', 'Running Shoes', 1001, 'john.smith@email.com', 'John Smith', '2023-05-15', NULL),

-- Invalid quantity (should be caught by CHECK constraint)
('ORD-005', '2025-01-19', 0, 19.99, 'P1006', 'SKU-SP-001', 'Yoga Mat', 1004, 'alice@email.com', 'Alice Brown', '2024-03-05', NULL),

-- Negative price (should be caught)
('ORD-005', '2025-01-19', 1, -5.00, 'P1007', 'SKU-SP-002', 'Water Bottle', 1004, 'alice@email.com', 'Alice Brown', '2024-03-05', 'Discount?'),

-- Future membership date (data quality issue)
('ORD-006', '2025-01-20', 1, 299.99, 'P1008', 'SKU-EL-003', 'Tablet', 1005, 'charlie@email.com', 'Charlie Davis', '2026-01-01', 'Pre-order'),

-- Duplicate product (same product_number with different names)
('ORD-007', '2025-01-21', 1, 499.99, 'P1002', 'SKU-EL-002', '4K Smart TV - 55"', 1006, 'diana@email.com', 'Diana Evans', '2024-04-10', NULL),

-- Missing email (NULL)
('ORD-008', '2025-01-22', 2, 14.99, 'P1009', 'SKU-BK-002', 'Cookbook', 1007, NULL, 'Frank Green', '2024-05-15', NULL),

-- Invalid email format
('ORD-009', '2025-01-23', 1, 39.99, 'P1010', 'SKU-HG-002', 'Blender', 1008, 'invalid-email', 'Grace Lee', '2024-06-20', NULL),

-- Multiple orders for same customer
('ORD-010', '2025-01-24', 1, 24.99, 'P1011', 'SKU-CL-002', 'Winter Jacket', 1002, 'jane@email.com', 'Jane Doe', '2024-01-10', NULL),
('ORD-011', '2025-01-25', 2, 34.99, 'P1012', 'SKU-CL-003', 'Jeans', 1002, 'jane@email.com', 'Jane Doe', '2024-01-10', NULL),

-- Long notes field
('ORD-012', '2025-01-26', 1, 199.99, 'P1013', 'SKU-EL-004', 'Smart Watch', 1009, 'henry@email.com', 'Henry Kim', '2024-07-01', 
 'Customer requested gift wrapping with red paper and a handwritten note saying "Happy Birthday!" Also needs delivery by Friday.');

PRINT 'Sample denormalized data loaded';
