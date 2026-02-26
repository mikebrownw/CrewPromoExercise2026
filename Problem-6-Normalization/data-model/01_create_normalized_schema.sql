-- SQL Server (T-SQL)
-- Normalized Data Model for Orders (3NF)

-- =======================================================================
-- STEP 1: Create Customer dimension (removes customer redundancy)
-- =======================================================================
CREATE TABLE dim_customer (
    customer_id INT PRIMARY KEY,
    email VARCHAR(100) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    membership_date DATE,
    notes NVARCHAR(MAX),
    -- Business constraints
    created_at DATETIME2 DEFAULT GETDATE(),
    
    -- UNIQUE constraints
    CONSTRAINT uq_customer_email UNIQUE (email),
    
    -- CHECK constraints
    CONSTRAINT chk_customer_email_format CHECK (
        email LIKE '%_@__%.__%'  -- Very basic email format check
    ),
    CONSTRAINT chk_membership_date_not_future CHECK (
        membership_date <= CAST(GETDATE() AS DATE)
    )
);

-- =======================================================================
-- STEP 2: Create Product dimension (removes product redundancy)
-- =======================================================================
CREATE TABLE dim_product (
    product_id INT PRIMARY KEY,
    product_number VARCHAR(50) NOT NULL,
    sku VARCHAR(50) NOT NULL,
    product_name VARCHAR(200) NOT NULL,
    
    -- UNIQUE constraints
    CONSTRAINT uq_product_number UNIQUE (product_number),
    CONSTRAINT uq_product_sku UNIQUE (sku),
    
    -- CHECK constraints
    CONSTRAINT chk_product_number_not_empty CHECK (
        LEN(TRIM(product_number)) > 0
    ),
    CONSTRAINT chk_sku_not_empty CHECK (
        LEN(TRIM(sku)) > 0
    )
);

-- =======================================================================
-- STEP 3: Create Date dimension (for time intelligence)
-- =======================================================================
CREATE TABLE dim_date (
    date_key INT PRIMARY KEY,  -- Format: YYYYMMDD
    full_date DATE NOT NULL UNIQUE,
    year INT NOT NULL,
    quarter INT NOT NULL,
    month INT NOT NULL,
    month_name VARCHAR(20) NOT NULL,
    day INT NOT NULL,
    day_of_week INT NOT NULL,
    day_name VARCHAR(20) NOT NULL,
    is_weekend BIT NOT NULL,
    
    -- CHECK constraints
    CONSTRAINT chk_valid_date CHECK (
        year BETWEEN 2000 AND 2100
    )
);

-- =======================================================================
-- STEP 4: Create Fact Orders table (the core transaction table)
-- =======================================================================
CREATE TABLE fact_orders (
    order_number VARCHAR(50) NOT NULL,  -- Could be alphanumeric
    order_date_key INT NOT NULL,        -- Foreign key to dim_date
    customer_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    price DECIMAL(18,2) NOT NULL,
    
    -- Composite primary key (assuming order_number + product is unique per line)
    CONSTRAINT pk_fact_orders PRIMARY KEY (order_number, product_id),
    
    -- Foreign key constraints
    CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id) 
        REFERENCES dim_customer(customer_id),
    CONSTRAINT fk_orders_product FOREIGN KEY (product_id) 
        REFERENCES dim_product(product_id),
    CONSTRAINT fk_orders_date FOREIGN KEY (order_date_key) 
        REFERENCES dim_date(date_key),
    
    -- CHECK constraints for data quality
    CONSTRAINT chk_quantity_positive CHECK (quantity > 0),
    CONSTRAINT chk_price_non_negative CHECK (price >= 0),
    CONSTRAINT chk_order_number_not_empty CHECK (
        LEN(TRIM(order_number)) > 0
    )
);

-- =======================================================================
-- STEP 5: Create indexes for performance
-- =======================================================================
CREATE INDEX idx_fact_orders_customer ON fact_orders(customer_id);
CREATE INDEX idx_fact_orders_product ON fact_orders(product_id);
CREATE INDEX idx_fact_orders_date ON fact_orders(order_date_key);
CREATE INDEX idx_fact_orders_order_num ON fact_orders(order_number);

-- =======================================================================
-- STEP 6: Create audit/log table for data quality issues
-- =======================================================================
CREATE TABLE data_quality_issues (
    issue_id INT IDENTITY PRIMARY KEY,
    source_row VARCHAR(MAX),  -- Store original CSV row
    issue_type VARCHAR(50),
    issue_description VARCHAR(500),
    created_at DATETIME2 DEFAULT GETDATE()
);

-- =======================================================================
-- STEP 7: Optional - Create a view to reconstruct denormalized format
-- =======================================================================
CREATE VIEW vw_denormalized_orders
AS
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
INNER JOIN dim_customer dc ON fo.customer_id = dc.customer_id
INNER JOIN dim_product dp ON fo.product_id = dp.product_id;

PRINT 'Normalized schema created successfully';

-- =======================================================================
-- NORMALIZATION EXPLANATION (3NF)
-- =======================================================================

/*
Original Denormalized Table:
-------------------------------------------------------------------------
| Order# | Date | Qty | Price | Prod# | SKU | Product | CustID | Email | Name | MemberDate | Notes |
-------------------------------------------------------------------------

Normalized Tables (3NF):

1. dim_customer
   - Removes redundancy: Customer details stored once
   - Benefits: Update email in one place, consistent customer data
   - 3NF: All non-key fields depend on customer_id

2. dim_product
   - Removes redundancy: Product details stored once
   - Benefits: Product information consistent across orders
   - 3NF: All fields depend on product_id

3. dim_date
   - Removes date redundancy and enables time intelligence
   - Benefits: Consistent date formatting, easy date-based aggregations
   - 3NF: All date attributes depend on the date

4. fact_orders
   - Core transaction table
   - Only contains foreign keys and measures
   - Benefits: Minimal storage, fast aggregations
   - 3NF: quantity and price depend on the combination of order + product

Normalization Benefits:
- Eliminates data redundancy
- Prevents update anomalies
- Ensures data consistency
- Reduces storage
- Improves query performance for analytics
*/
