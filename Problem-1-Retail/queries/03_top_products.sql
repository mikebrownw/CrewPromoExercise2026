-- SQL Server (T-SQL) using Common Table Expression and Window Function
-- Purpose: For each category, list the top 3 products by revenue in 2025.
-- Handles ties using DENSE_RANK (gives same rank to ties, no gaps)

WITH product_revenue AS (
    -- First, calculate revenue per product
    SELECT 
        p.category,
        p.product_id,
        p.name AS product_name,
        p.sku,
        SUM(oi.qty * oi.price) AS product_revenue,
        COUNT(DISTINCT o.order_id) AS times_ordered
    FROM 
        products p
        INNER JOIN order_items oi 
            ON p.product_id = oi.product_id
        INNER JOIN orders o 
            ON oi.order_id = o.order_id
    WHERE 
        o.order_date >= '2025-01-01' 
        AND o.order_date < '2026-01-01'
        AND o.status = 'completed'
    GROUP BY 
        p.category, p.product_id, p.name, p.sku
),
ranked_products AS (
    -- Then rank them within each category
    SELECT 
        *,
        -- DENSE_RANK handles ties by giving same rank to equal revenues
        DENSE_RANK() OVER (
            PARTITION BY category 
            ORDER BY product_revenue DESC
        ) AS revenue_rank
    FROM 
        product_revenue
)
-- Finally, return top 3 (including ties)
SELECT 
    category,
    product_id,
    product_name,
    sku,
    -- Format revenue for readability
    FORMAT(product_revenue, 'C', 'en-us') AS formatted_revenue,
    product_revenue,
    times_ordered,
    revenue_rank
FROM 
    ranked_products
WHERE 
    revenue_rank <= 3  -- Top 3 products per category (with ties)
ORDER BY 
    category,
    revenue_rank,
    product_revenue DESC;

/* Key Points:
   - DENSE_RANK ensures if 2nd and 3rd tie, both get rank 2, next gets rank 3
   - Using RANK() would skip numbers after ties (1,2,2,4) - less ideal for "top 3"
   - CTEs improve readability and maintainability
*/
