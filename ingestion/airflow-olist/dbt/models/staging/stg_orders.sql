SELECT
    TRIM(order_id)                                                           AS order_id,
    TRIM(customer_id)                                                        AS customer_id,
    TRIM(LOWER(order_status))                                                AS order_status,
    TRY_TO_TIMESTAMP_NTZ(order_purchase_timestamp, 'YYYY-MM-DD HH24:MI:SS') AS order_purchase_timestamp,
    TRY_TO_TIMESTAMP_NTZ(order_approved_at, 'YYYY-MM-DD HH24:MI:SS')        AS order_approved_at,
    TRY_TO_TIMESTAMP_NTZ(order_delivered_carrier_date, 'YYYY-MM-DD HH24:MI:SS') AS order_delivered_carrier_date,
    TRY_TO_TIMESTAMP_NTZ(order_delivered_customer_date, 'YYYY-MM-DD HH24:MI:SS') AS order_delivered_customer_date,
    TRY_TO_TIMESTAMP_NTZ(order_estimated_delivery_date, 'YYYY-MM-DD HH24:MI:SS') AS order_estimated_delivery_date
FROM {{ source('raw', 'raw_orders') }}
WHERE TRIM(order_id) IS NOT NULL AND TRIM(customer_id) IS NOT NULL