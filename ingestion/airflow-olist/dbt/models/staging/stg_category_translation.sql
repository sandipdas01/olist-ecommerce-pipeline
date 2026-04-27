SELECT
    TRIM(product_category_name)                         AS product_category_name,
    NULLIF(TRIM(product_category_name_english), '')     AS product_category_name_english
FROM {{ source('raw', 'raw_category_translation') }}
WHERE TRIM(product_category_name) IS NOT NULL