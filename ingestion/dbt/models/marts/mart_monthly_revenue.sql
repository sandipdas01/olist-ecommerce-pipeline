SELECT
    d.year,
    d.month,
    COUNT(f.order_id)          AS total_orders,
    SUM(fi.total_item_value)   AS total_revenue
FROM {{ ref('fact_orders') }} f
JOIN {{ ref('fact_order_items') }} fi ON f.order_id = fi.order_id
JOIN {{ ref('dim_dates') }} d ON f.purchase_date_key = d.date_key
GROUP BY 1, 2
ORDER BY 1, 2