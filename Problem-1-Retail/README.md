# Problem 1: Retail (Orders & Revenue Analytics)

## Schema
- customers(customer_id PK, first_name, last_name, email, region, created_at)
- orders(order_id PK, order_date TIMESTAMP, customer_id FK, status, total_amount)
- order_items(order_id FK, product_id FK, qty INT, price NUMERIC(18,2))
- products(product_id PK, category, sku, name)

## Questions
1. Return the latest 10 completed orders in 2025, with customer full name and order total.
2. Show categories with ≥ $1M revenue in 2025.
3. For each category, list the top 3 products by revenue in 2025.
4. Pivot 2025 monthly revenue per category into 12 columns.
5. Discuss indexes/partitions for performance optimization; include SARGability and materialized views.
