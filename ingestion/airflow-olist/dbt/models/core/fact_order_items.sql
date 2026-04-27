SELECT
    oi.order_id,
    oi.order_item_id,
    dp.product_id                                                   AS product_key,
    ds.seller_id                                                    AS seller_key,
    oi.shipping_limit_date,
    oi.price,
    oi.freight_value,
    COALESCE(oi.price, 0) + COALESCE(oi.freight_value, 0)          AS total_item_value
FROM {{ ref('stg_order_items') }} oi
LEFT JOIN {{ ref('dim_products') }} dp ON oi.product_id = dp.product_id
LEFT JOIN {{ ref('dim_sellers') }}  ds ON oi.seller_id  = ds.seller_id