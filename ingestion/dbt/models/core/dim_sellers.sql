SELECT
    seller_id,
    MAX(seller_zip_code_prefix) AS seller_zip_code_prefix,
    MAX(seller_city)            AS seller_city,
    MAX(seller_state)           AS seller_state
FROM {{ ref('stg_sellers') }}
GROUP BY seller_id