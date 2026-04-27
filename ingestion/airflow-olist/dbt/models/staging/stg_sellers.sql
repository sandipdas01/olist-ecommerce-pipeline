SELECT
    TRIM(seller_id)                             AS seller_id,
    NULLIF(TRIM(seller_zip_code_prefix), '')    AS seller_zip_code_prefix,
    NULLIF(INITCAP(TRIM(seller_city)), '')      AS seller_city,
    NULLIF(UPPER(TRIM(seller_state)), '')       AS seller_state
FROM {{ source('raw', 'raw_sellers') }}
WHERE TRIM(seller_id) IS NOT NULL