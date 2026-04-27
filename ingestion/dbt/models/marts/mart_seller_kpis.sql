SELECT
    s.seller_id,
    s.seller_city,
    s.seller_state,
    COUNT(DISTINCT f.order_id)  AS total_orders,
    SUM(fi.total_item_value)    AS total_revenue,
    AVG(f.days_to_customer)     AS avg_delivery_days
FROM {{ ref('fact_orders') }} f
JOIN {{ ref('fact_order_items') }} fi ON f.order_id = fi.order_id
JOIN {{ ref('dim_sellers') }} s ON fi.seller_key = s.seller_id
GROUP BY 1, 2, 3
ORDER BY 5 DESC