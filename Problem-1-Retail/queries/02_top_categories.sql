-- SQL Server (T-SQL)
-- Purpose: Show categories with ≥ $1M revenue in 2025.

PRINT '========== QUERY 2: Show categories with ≥ $1M revenue in 2025. ==========';

SELECT 
    p.category,
    -- Calculate total revenue with proper decimal handling
    CAST(SUM(oi.qty * oi.price) AS DECIMAL(12,2)) AS total_revenue_2025,
    -- Additional business context: average order value per category
    CAST(AVG(oi.qty * oi.price) AS DECIMAL(10,2)) AS avg_transaction_value,
    COUNT(DISTINCT o.order_id) AS number_of_orders
FROM 
    products p
    INNER JOIN order_items oi 
        ON p.product_id = oi.product_id
    INNER JOIN orders o 
        ON oi.order_id = o.order_id
WHERE 
    -- SARGable date filter (no functions)
    o.order_date >= '2025-01-01' 
    AND o.order_date < '2026-01-01'
    AND o.status = 'completed'  -- Only count revenue from completed orders
GROUP BY 
    p.category
HAVING 
    -- Post-group filter for million-dollar categories
    SUM(oi.qty * oi.price) >= 1000000
ORDER BY 
    total_revenue_2025 DESC;

/* Business Value:
   - Identifies categories driving significant revenue
   - HAVING clause filters after aggregation (more efficient than subquery)
   - Additional metrics provide deeper insight than just the threshold
*/
