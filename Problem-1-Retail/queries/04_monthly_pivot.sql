WITH monthly_category_revenue AS (
    -- First, aggregate revenue by category and month
    SELECT 
        p.category,
        MONTH(o.order_date) AS month_num,
        SUM(oi.qty * oi.price) AS monthly_revenue
    FROM 
        products p
        INNER JOIN order_items oi ON p.product_id = oi.product_id
        INNER JOIN orders o ON oi.order_id = o.order_id
    WHERE 
        o.order_date >= '2025-01-01' 
        AND o.order_date < '2026-01-01'
        AND o.status = 'completed'
    GROUP BY 
        p.category, 
        MONTH(o.order_date)  -- Group by category and month
)
-- Now pivot: each category becomes one row, months become columns
SELECT 
    category,
    -- Use COALESCE to show 0 for months with no revenue
    COALESCE([1], 0) AS Jan,
    COALESCE([2], 0) AS Feb,
    COALESCE([3], 0) AS Mar,
    COALESCE([4], 0) AS Apr,
    COALESCE([5], 0) AS May,
    COALESCE([6], 0) AS Jun,
    COALESCE([7], 0) AS Jul,
    COALESCE([8], 0) AS Aug,
    COALESCE([9], 0) AS Sep,
    COALESCE([10], 0) AS Oct,
    COALESCE([11], 0) AS Nov,
    COALESCE([12], 0) AS Dec,
    -- Add a total column for convenience
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
