SELECT
    o.order_id,
    dc.customer_unique_id                                                           AS customer_key,
    o.order_status,
    TO_NUMBER(TO_CHAR(o.order_purchase_timestamp, 'YYYYMMDD'))                      AS purchase_date_key,
    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    DATEDIFF('day', o.order_purchase_timestamp, o.order_delivered_carrier_date)     AS days_to_carrier,
    DATEDIFF('day', o.order_purchase_timestamp, o.order_delivered_customer_date)    AS days_to_customer,
    DATEDIFF('day', o.order_purchase_timestamp, o.order_estimated_delivery_date)    AS days_estimated,
    DATEDIFF('day', o.order_estimated_delivery_date, o.order_delivered_customer_date) AS delivery_delay_days
FROM {{ ref('stg_orders') }} o
LEFT JOIN {{ ref('dim_customers') }} dc
    ON o.customer_id = dc.customer_unique_id