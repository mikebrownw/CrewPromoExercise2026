-- SQL Server (T-SQL)
-- Complete Data Model for Retail Analytics Exercise

-- Create customers table
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    region VARCHAR(50),
    created_at DATETIME2 DEFAULT GETDATE()
);

-- Create products table
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    category VARCHAR(100) NOT NULL,
    sku VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(200) NOT NULL
);

-- Create orders table
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    order_date DATETIME2 NOT NULL,
    customer_id INT NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('pending', 'completed', 'cancelled', 'refunded')),
    total_amount DECIMAL(10,2),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- Create order_items table
CREATE TABLE order_items (
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    qty INT NOT NULL CHECK (qty > 0),
    price DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (order_id, product_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- Create indexes for performance
CREATE INDEX idx_orders_status_date ON orders(status, order_date) INCLUDE (customer_id, total_amount);
CREATE INDEX idx_orders_customer_date ON orders(customer_id, order_date DESC) INCLUDE (status, total_amount);
CREATE INDEX idx_order_items_product ON order_items(product_id) INCLUDE (qty, price);

PRINT 'All tables created successfully';
