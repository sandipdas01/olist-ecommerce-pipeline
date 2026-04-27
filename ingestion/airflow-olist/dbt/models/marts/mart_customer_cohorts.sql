SELECT
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,
    COUNT(DISTINCT f.order_id)  AS total_orders,
    SUM(fi.total_item_value)    AS lifetime_value
FROM {{ ref('fact_orders') }} f
JOIN {{ ref('dim_customers') }} c ON f.customer_key = c.customer_unique_id
JOIN {{ ref('fact_order_items') }} fi ON f.order_id = fi.order_id
WHERE f.customer_key IS NOT NULL
GROUP BY 1, 2, 3
ORDER BY 5 DESC