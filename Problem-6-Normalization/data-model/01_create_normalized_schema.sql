-- SQL Server (T-SQL)
-- Normalized Data Model for Orders (3NF- Thrid Normal Form)

-- =======================================================================
-- WHAT WE'RE STARTING WITH (Denormalized CSV):
-- =======================================================================
/*
One big table with all data mixed together:

Order Number, Order Date, Quantity, Price, Product Number, SKU, Product, 
Customer ID, Email, Name, Membership Date, Notes

PROBLEMS with this structure:
- Same customer info repeated for every order (wasted space)
- Same product info repeated for every order (wasted space)
- If customer email changes, need to update many rows
- Risk of inconsistent data (same customer different emails)
*/

-- =======================================================================
-- SOLUTION: Split into 4 tables (3NF Normalization)
-- =======================================================================

-- -----------------------------------------------------------------------
-- TABLE 1: dim_customer - Store each customer ONCE
-- -----------------------------------------------------------------------
CREATE TABLE dim_customer (
    customer_id INT PRIMARY KEY,           -- Unique ID for each customer
    email VARCHAR(100) NOT NULL,           -- Customer email
    full_name VARCHAR(100) NOT NULL,       -- Customer name
    membership_date DATE,                  -- When they joined
    notes NVARCHAR(MAX),                   -- Any special notes
    created_at DATETIME2 DEFAULT GETDATE(),-- When record was created
    
    -- BUSINESS RULES:
    CONSTRAINT uq_customer_email UNIQUE (email),  -- No duplicate emails
    CONSTRAINT chk_email_format CHECK (           -- Basic email validation
        email LIKE '%_@__%.__%'
    ),
    CONSTRAINT chk_membership_not_future CHECK (  -- Can't have future date
        membership_date <= CAST(GETDATE() AS DATE)
    )
);

-- -----------------------------------------------------------------------
-- TABLE 2: dim_product - Store each product ONCE
-- -----------------------------------------------------------------------
CREATE TABLE dim_product (
    product_id INT PRIMARY KEY,            -- Unique ID for each product
    product_number VARCHAR(50) NOT NULL,   -- Product code from system
    sku VARCHAR(50) NOT NULL,              -- Stock keeping unit
    product_name VARCHAR(200) NOT NULL,    -- Product description
    
    -- BUSINESS RULES:
    CONSTRAINT uq_product_number UNIQUE (product_number),  -- No duplicate product codes
    CONSTRAINT uq_product_sku UNIQUE (sku),                -- No duplicate SKUs
    CONSTRAINT chk_product_not_empty CHECK (LEN(TRIM(product_number)) > 0),
    CONSTRAINT chk_sku_not_empty CHECK (LEN(TRIM(sku)) > 0)
);

-- -----------------------------------------------------------------------
-- TABLE 3: dim_date - Store dates for easy reporting
-- -----------------------------------------------------------------------
/*
Why a separate date table? Makes it easy to:
- Filter by year/month/quarter
- Compare same month across years
- Calculate rolling averages
*/
CREATE TABLE dim_date (
    date_key INT PRIMARY KEY,              -- Format: 20250227 (YYYYMMDD)
    full_date DATE NOT NULL UNIQUE,        -- Actual date
    year INT NOT NULL,                      -- 2025
    quarter INT NOT NULL,                   -- 1,2,3,4
    month INT NOT NULL,                     -- 1-12
    month_name VARCHAR(20) NOT NULL,        -- 'January', etc.
    day INT NOT NULL,                        -- 1-31
    day_of_week INT NOT NULL,                -- 1-7
    day_name VARCHAR(20) NOT NULL,           -- 'Monday', etc.
    is_weekend BIT NOT NULL                   -- 1 for Sat/Sun
);

-- -----------------------------------------------------------------------
-- TABLE 4: fact_orders - Store ONLY the transaction facts
-- -----------------------------------------------------------------------
/*
This table is "thin" - it only contains:
- IDs pointing to other tables (foreign keys)
- Numbers that change per order (quantity, price)
*/
CREATE TABLE fact_orders (
    order_number VARCHAR(50) NOT NULL,      -- Order ID from CSV
    order_date_key INT NOT NULL,            -- Points to dim_date
    customer_id INT NOT NULL,                -- Points to dim_customer
    product_id INT NOT NULL,                  -- Points to dim_product
    quantity INT NOT NULL,                    -- How many bought
    price DECIMAL(18,2) NOT NULL,             -- Price per unit
    
    -- Each order can have multiple products, so we need both
    CONSTRAINT pk_fact_orders PRIMARY KEY (order_number, product_id),
    
    -- Link to other tables (referential integrity)
    CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id) 
        REFERENCES dim_customer(customer_id),
    CONSTRAINT fk_orders_product FOREIGN KEY (product_id) 
        REFERENCES dim_product(product_id),
    CONSTRAINT fk_orders_date FOREIGN KEY (order_date_key) 
        REFERENCES dim_date(date_key),
    
    -- Data quality rules
    CONSTRAINT chk_quantity_positive CHECK (quantity > 0),
    CONSTRAINT chk_price_non_negative CHECK (price >= 0),
    CONSTRAINT chk_order_not_empty CHECK (LEN(TRIM(order_number)) > 0)
);

-- =======================================================================
-- WHAT WE GAINED:
-- =======================================================================
/*
Before (Denormalized):
- 1 table with 12 columns
- Customer info repeated 1000s of times
- Risk of inconsistent data

After (Normalized):
- 4 tables with clear purposes
- Customer stored once → update in one place
- Product stored once → consistent descriptions
- Date table → easy time-based analysis
- Fact table → fast aggregations

HOW THEY CONNECT:
    fact_orders.order_date_key → dim_date.date_key
    fact_orders.customer_id    → dim_customer.customer_id
    fact_orders.product_id      → dim_product.product_id
*/
