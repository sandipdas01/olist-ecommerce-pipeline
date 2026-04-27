USE DATABASE OLIST_PROD_RAW;
USE SCHEMA OLIST;

-- Audit table
CREATE TABLE IF NOT EXISTS load_audit (
    audit_id         NUMBER AUTOINCREMENT,
    source_table     VARCHAR,
    source_file      VARCHAR,
    rows_loaded      NUMBER,
    rows_rejected    NUMBER,
    load_status      VARCHAR,
    load_start_ts    TIMESTAMP_NTZ,
    load_end_ts      TIMESTAMP_NTZ,
    pipeline_run_id  VARCHAR,
    error_message    VARCHAR,
    inserted_at      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- 1. Orders
CREATE TABLE IF NOT EXISTS raw_orders (
    order_id                        VARCHAR,
    customer_id                     VARCHAR,
    order_status                    VARCHAR,
    order_purchase_timestamp        VARCHAR,
    order_approved_at               VARCHAR,
    order_delivered_carrier_date    VARCHAR,
    order_delivered_customer_date   VARCHAR,
    order_estimated_delivery_date   VARCHAR,
    _source_file                    VARCHAR,
    _loaded_at                      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- 2. Customers
CREATE TABLE IF NOT EXISTS raw_customers (
    customer_id                 VARCHAR,
    customer_unique_id          VARCHAR,
    customer_zip_code_prefix    VARCHAR,
    customer_city               VARCHAR,
    customer_state              VARCHAR,
    _source_file                VARCHAR,
    _loaded_at                  TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- 3. Order Items
CREATE TABLE IF NOT EXISTS raw_order_items (
    order_id            VARCHAR,
    order_item_id       VARCHAR,
    product_id          VARCHAR,
    seller_id           VARCHAR,
    shipping_limit_date VARCHAR,
    price               VARCHAR,
    freight_value       VARCHAR,
    _source_file        VARCHAR,
    _loaded_at          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- 4. Order Payments
CREATE TABLE IF NOT EXISTS raw_order_payments (
    order_id             VARCHAR,
    payment_sequential   VARCHAR,
    payment_type         VARCHAR,
    payment_installments VARCHAR,
    payment_value        VARCHAR,
    _source_file         VARCHAR,
    _loaded_at           TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- 5. Order Reviews
CREATE TABLE IF NOT EXISTS raw_order_reviews (
    review_id                VARCHAR,
    order_id                 VARCHAR,
    review_score             VARCHAR,
    review_comment_title     VARCHAR,
    review_comment_message   VARCHAR,
    review_creation_date     VARCHAR,
    review_answer_timestamp  VARCHAR,
    _source_file             VARCHAR,
    _loaded_at               TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- 6. Products
CREATE TABLE IF NOT EXISTS raw_products (
    product_id                  VARCHAR,
    product_category_name       VARCHAR,
    product_name_length         VARCHAR,
    product_description_length  VARCHAR,
    product_photos_qty          VARCHAR,
    product_weight_g            VARCHAR,
    product_length_cm           VARCHAR,
    product_height_cm           VARCHAR,
    product_width_cm            VARCHAR,
    _source_file                VARCHAR,
    _loaded_at                  TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- 7. Sellers
CREATE TABLE IF NOT EXISTS raw_sellers (
    seller_id               VARCHAR,
    seller_zip_code_prefix  VARCHAR,
    seller_city             VARCHAR,
    seller_state            VARCHAR,
    _source_file            VARCHAR,
    _loaded_at              TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- 8. Geolocation
CREATE TABLE IF NOT EXISTS raw_geolocation (
    geolocation_zip_code_prefix VARCHAR,
    geolocation_lat             VARCHAR,
    geolocation_lng             VARCHAR,
    geolocation_city            VARCHAR,
    geolocation_state           VARCHAR,
    _source_file                VARCHAR,
    _loaded_at                  TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- 9. Category Translation
CREATE TABLE IF NOT EXISTS raw_category_translation (
    product_category_name           VARCHAR,
    product_category_name_english   VARCHAR,
    _source_file                    VARCHAR,
    _loaded_at                      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);