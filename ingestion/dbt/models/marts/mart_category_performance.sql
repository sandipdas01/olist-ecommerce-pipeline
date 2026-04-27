SELECT
    p.product_category_name_english                             AS category,
    COUNT(DISTINCT f.order_id)                                  AS total_orders,
    SUM(fi.total_item_value)                                    AS total_revenue,
    DIV0(SUM(fi.total_item_value), COUNT(DISTINCT f.order_id))  AS aov
FROM {{ ref('fact_orders') }} f
JOIN {{ ref('fact_order_items') }} fi ON f.order_id = fi.order_id
JOIN {{ ref('dim_products') }} p ON fi.product_key = p.product_id
WHERE p.product_category_name_english IS NOT NULL
GROUP BY 1
ORDER BY 3 DESC