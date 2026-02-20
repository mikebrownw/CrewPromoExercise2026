-- SQL Server (T-SQL) using PIVOT operator
-- Purpose: Create a matrix report showing monthly revenue trends by category
-- Ideal for executive dashboards and trend analysis

WITH monthly_category_revenue AS (
    -- Base data: aggregate revenue by category and month
    SELECT 
        p.category,
        -- Extract month number for pivoting (1-12)
        MONTH(o.order_date) AS month_num,
        -- Also include month name for reference (not used in pivot)
        DATENAME(month, o.order_date) AS month_name,
        SUM(oi.qty * oi.price) AS monthly_revenue
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
        p.category,
        MONTH(o.order_date),  -- GROUP BY works with this expression
        DATENAME(month, o.order_date)
)
-- Pivot the data: months become columns
SELECT 
    category,
    -- Explicitly name the 12 month columns
    COALESCE([1], 0) AS Jan_2025,
    COALESCE([2], 0) AS Feb_2025,
    COALESCE([3], 0) AS Mar_2025,
    COALESCE([4], 0) AS Apr_2025,
    COALESCE([5], 0) AS May_2025,
    COALESCE([6], 0) AS Jun_2025,
    COALESCE([7], 0) AS Jul_2025,
    COALESCE([8], 0) AS Aug_2025,
    COALESCE([9], 0) AS Sep_2025,
    COALESCE([10], 0) AS Oct_2025,
    COALESCE([11], 0) AS Nov_2025,
    COALESCE([12], 0) AS Dec_2025,
    -- Add total row for each category
    COALESCE([1], 0) + COALESCE([2], 0) + COALESCE([3], 0) + 
    COALESCE([4], 0) + COALESCE([5], 0) + COALESCE([6], 0) + 
    COALESCE([7], 0) + COALESCE([8], 0) + COALESCE([9], 0) + 
    COALESCE([10], 0) + COALESCE([11], 0) + COALESCE([12], 0) AS total_2025
FROM 
    monthly_category_revenue
    PIVOT (
        SUM(monthly_revenue)  -- Aggregate function
        FOR month_num IN ([1], [2], [3], [4], [5], [6], 
                          [7], [8], [9], [10], [11], [12])  -- Pivot on month number
    ) AS pivot_table
ORDER BY 
    total_2025 DESC;  -- Most valuable categories first

/* Alternative Approach using Conditional Aggregation (works in all SQL dialects):
   SELECT
       category,
       SUM(CASE WHEN MONTH(order_date) = 1 THEN revenue ELSE 0 END) AS Jan,
       ... etc.
   This is often more portable but less elegant than PIVOT
*/
