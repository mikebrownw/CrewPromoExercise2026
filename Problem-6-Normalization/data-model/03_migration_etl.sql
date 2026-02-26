-- SQL Server (T-SQL)
-- ETL Process: Migrate from denormalized staging to normalized schema
-- Includes data cleansing, validation, and error handling

-- =======================================================================
-- STEP 1: Populate Date Dimension (first, since it's independent)
-- =======================================================================
-- Generate dates for a reasonable range (2020-2030)
WITH date_range AS (
    SELECT CAST('2020-01-01' AS DATE) AS date_val
    UNION ALL
    SELECT DATEADD(day, 1, date_val)
    FROM date_range
    WHERE date_val < '2030-12-31'
)
INSERT INTO dim_date (date_key, full_date, year, quarter, month, month_name, 
                      day, day_of_week, day_name, is_weekend)
SELECT 
    CAST(CONVERT(VARCHAR, date_val, 112) AS INT) AS date_key,
    date_val AS full_date,
    YEAR(date_val) AS year,
    DATEPART(quarter, date_val) AS quarter,
    MONTH(date_val) AS month,
    DATENAME(month, date_val) AS month_name,
    DAY(date_val) AS day,
    DATEPART(weekday, date_val) AS day_of_week,
    DATENAME(weekday, date_val) AS day_name,
    CASE WHEN DATEPART(weekday, date_val) IN (1, 7) THEN 1 ELSE 0 END AS is_weekend
FROM date_range
OPTION (MAXRECURSION 0);

-- =======================================================================
-- STEP 2: Cleanse and Load Customer Dimension
-- =======================================================================
BEGIN TRANSACTION;
BEGIN TRY
    -- First, identify and handle duplicates (keep the most recent based on membership_date)
    WITH ranked_customers AS (
        SELECT 
            customer_id,
            email,
            name,
            membership_date,
            notes,
            -- Keep the record with most recent membership_date
            ROW_NUMBER() OVER (
                PARTITION BY customer_id 
                ORDER BY 
                    CASE WHEN email IS NOT NULL AND email LIKE '%_@__%.__%' THEN 1 ELSE 2 END,  -- Prefer valid emails
                    membership_date DESC NULLS LAST,
                    order_date DESC  -- Most recent order
            ) AS rn
        FROM staging_orders
        WHERE customer_id IS NOT NULL
    ),
    unique_customers AS (
        SELECT 
            customer_id,
            -- Clean email: use first non-NULL, valid email
            MAX(CASE 
                WHEN email IS NOT NULL AND email LIKE '%_@__%.__%' THEN email 
                ELSE NULL 
            END) AS clean_email,
            MAX(name) AS clean_name,
            MAX(membership_date) AS clean_membership_date,
            MAX(notes) AS clean_notes
        FROM ranked_customers
        WHERE rn = 1
        GROUP BY customer_id
    )
    INSERT INTO dim_customer (customer_id, email, full_name, membership_date, notes)
    SELECT 
        customer_id,
        COALESCE(clean_email, 'unknown_' + CAST(customer_id AS VARCHAR) + '@email.com') AS email,
        COALESCE(clean_name, 'Unknown Customer') AS full_name,
        CASE 
            WHEN clean_membership_date <= CAST(GETDATE() AS DATE) THEN clean_membership_date
            ELSE NULL  -- Don't allow future dates
        END AS membership_date,
        clean_notes
    FROM unique_customers;
    
    -- Log any customers that were skipped or had issues
    INSERT INTO data_quality_issues (source_row, issue_type, issue_description)
    SELECT 
        'Customer ID: ' + CAST(customer_id AS VARCHAR),
        'Missing Required Field',
        'Customer has no valid email address'
    FROM staging_orders
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
    HAVING MAX(CASE WHEN email IS NOT NULL AND email LIKE '%_@__%.__%' THEN 1 ELSE 0 END) = 0;
    
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    THROW;
END CATCH;
COMMIT TRANSACTION;

-- =======================================================================
-- STEP 3: Cleanse and Load Product Dimension
-- =======================================================================
BEGIN TRANSACTION;
BEGIN TRY
    -- Handle product duplicates (prefer non-NULL, consistent data)
    WITH ranked_products AS (
        SELECT 
            product_number,
            sku,
            product,
            ROW_NUMBER() OVER (
                PARTITION BY product_number 
                ORDER BY 
                    CASE WHEN sku IS NOT NULL THEN 1 ELSE 2 END,
                    CASE WHEN product IS NOT NULL AND LEN(product) > 0 THEN 1 ELSE 2 END,
                    order_date DESC
            ) AS rn
        FROM staging_orders
        WHERE product_number IS NOT NULL
    ),
    unique_products AS (
        SELECT 
            product_number,
            MAX(sku) AS clean_sku,
            MAX(product) AS clean_product
        FROM ranked_products
        WHERE rn = 1
        GROUP BY product_number
    )
    INSERT INTO dim_product (product_id, product_number, sku, product_name)
    SELECT 
        ROW_NUMBER() OVER (ORDER BY product_number) + 1000 AS product_id,
        product_number,
        COALESCE(clean_sku, 'SKU-' + product_number) AS sku,
        COALESCE(clean_product, 'Unknown Product') AS product_name
    FROM unique_products
    WHERE product_number IS NOT NULL;
    
    -- Log products with issues
    INSERT INTO data_quality_issues (source_row, issue_type, issue_description)
    SELECT 
        'Product Number: ' + product_number,
        'Missing Product Name',
        'Product has no name defined'
    FROM staging_orders
    WHERE product_number IS NOT NULL AND (product IS NULL OR LEN(product) = 0)
    GROUP BY product_number;
    
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    THROW;
END CATCH;
COMMIT TRANSACTION;

-- =======================================================================
-- STEP 4: Load Fact Orders (with validation)
-- =======================================================================
BEGIN TRANSACTION;
BEGIN TRY
    INSERT INTO fact_orders (
        order_number,
        order_date_key,
        customer_id,
        product_id,
        quantity,
        price
    )
    SELECT 
        s.order_number,
        CAST(CONVERT(VARCHAR, s.order_date, 112) AS INT) AS order_date_key,
        s.customer_id,
        p.product_id,
        s.quantity,
        s.price
    FROM staging_orders s
    INNER JOIN dim_product p ON s.product_number = p.product_number
    WHERE 
        -- Only load valid records
        s.quantity > 0
        AND s.price >= 0
        AND s.order_date IS NOT NULL
        AND s.customer_id IN (SELECT customer_id FROM dim_customer)
        AND NOT EXISTS (  -- Avoid duplicates
            SELECT 1 FROM fact_orders f 
            WHERE f.order_number = s.order_number 
            AND f.product_id = p.product_id
        );
    
    -- Log records that failed validation
    INSERT INTO data_quality_issues (source_row, issue_type, issue_description)
    SELECT 
        'Order: ' + order_number + ', Product: ' + product_number,
        'Invalid Quantity',
        'Quantity must be > 0: ' + CAST(quantity AS VARCHAR)
    FROM staging_orders
    WHERE quantity <= 0;
    
    INSERT INTO data_quality_issues (source_row, issue_type, issue_description)
    SELECT 
        'Order: ' + order_number + ', Product: ' + product_number,
        'Invalid Price',
        'Price must be >= 0: ' + CAST(price AS VARCHAR)
    FROM staging_orders
    WHERE price < 0;
    
    INSERT INTO data_quality_issues (source_row, issue_type, issue_description)
    SELECT 
        'Order: ' + order_number + ', Product: ' + product_number,
        'Missing Date',
        'Order date is NULL'
    FROM staging_orders
    WHERE order_date IS NULL;
    
    INSERT INTO data_quality_issues (source_row, issue_type, issue_description)
    SELECT 
        'Order: ' + order_number + ', Product: ' + product_number,
        'Missing Customer',
        'Customer ID ' + CAST(customer_id AS VARCHAR) + ' not found in dim_customer'
    FROM staging_orders s
    WHERE customer_id IS NOT NULL
        AND NOT EXISTS (SELECT 1 FROM dim_customer d WHERE d.customer_id = s.customer_id);
    
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    THROW;
END CATCH;
COMMIT TRANSACTION;

-- =======================================================================
-- STEP 5: Data Quality Report
-- =======================================================================
SELECT 
    'Data Quality Summary' AS report,
    COUNT(*) AS total_staging_rows
FROM staging_orders
UNION ALL
SELECT 
    'Successfully Loaded Orders',
    COUNT(*)
FROM fact_orders
UNION ALL
SELECT 
    'Unique Customers',
    COUNT(*)
FROM dim_customer
UNION ALL
SELECT 
    'Unique Products',
    COUNT(*)
FROM dim_product
UNION ALL
SELECT 
    'Data Quality Issues',
    COUNT(*)
FROM data_quality_issues;

-- Show the issues
SELECT * FROM data_quality_issues;

PRINT 'ETL migration completed successfully';
