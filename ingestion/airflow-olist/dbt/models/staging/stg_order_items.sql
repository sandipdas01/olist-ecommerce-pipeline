SELECT
    TRIM(order_id)                                                          AS order_id,
    TRY_TO_NUMBER(order_item_id)                                            AS order_item_id,
    TRIM(product_id)                                                        AS product_id,
    TRIM(seller_id)                                                         AS seller_id,
    TRY_TO_TIMESTAMP_NTZ(shipping_limit_date, 'YYYY-MM-DD HH24:MI:SS')     AS shipping_limit_date,
    TRY_TO_NUMBER(price, 10, 2)                                             AS price,
    TRY_TO_NUMBER(freight_value, 10, 2)                                     AS freight_value
FROM {{ source('raw', 'raw_order_items') }}
WHERE TRIM(order_id) IS NOT NULL AND TRIM(product_id) IS NOT NULL