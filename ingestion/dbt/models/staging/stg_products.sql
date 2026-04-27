SELECT
    TRIM(product_id)                                AS product_id,
    NULLIF(TRIM(product_category_name), '')         AS product_category_name,
    TRY_TO_NUMBER(product_name_lenght)              AS product_name_length,
    TRY_TO_NUMBER(product_description_lenght)       AS product_description_length,
    TRY_TO_NUMBER(product_photos_qty)               AS product_photos_qty,
    TRY_TO_NUMBER(product_weight_g, 10, 2)          AS product_weight_g,
    TRY_TO_NUMBER(product_length_cm, 10, 2)         AS product_length_cm,
    TRY_TO_NUMBER(product_height_cm, 10, 2)         AS product_height_cm,
    TRY_TO_NUMBER(product_width_cm, 10, 2)          AS product_width_cm
FROM {{ source('raw', 'raw_products') }}
WHERE TRIM(product_id) IS NOT NULL