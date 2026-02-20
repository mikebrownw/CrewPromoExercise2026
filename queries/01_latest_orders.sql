-- SQL Server (T-SQL)
-- Purpose: Retrieve the 10 most recent completed orders from 2025
-- Includes customer name and order total for reporting/export

SELECT TOP 10
    -- Concatenate customer name for display
    CONCAT(c.first_name, ' ', c.last_name) AS customer_full_name,
    o.order_id,
    -- Format order date for readability
    FORMAT(o.order_date, 'yyyy-MM-dd HH:mm') AS order_date,
    -- Use COALESCE to handle any NULL totals (though shouldn't happen)
    COALESCE(o.total_amount, 0) AS order_total
FROM 
    orders o
    INNER JOIN customers c 
        ON o.customer_id = c.customer_id
WHERE 
    -- SARGable filter on order_date (no function wrapping the column)
    o.order_date >= '2025-01-01' 
    AND o.order_date < '2026-01-01'
    AND o.status = 'completed'  -- Exact match on status
ORDER BY 
    o.order_date DESC;  -- Most recent first

/* Performance Notes:
   - Index on (status, order_date, customer_id) would make this query extremely fast
   - INNER JOIN assumes every order has a valid customer (data integrity)
*/
