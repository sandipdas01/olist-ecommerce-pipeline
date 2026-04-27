SELECT
    TRIM(geolocation_zip_code_prefix)               AS geolocation_zip_code_prefix,
    TRY_TO_NUMBER(geolocation_lat, 18, 6)           AS geolocation_lat,
    TRY_TO_NUMBER(geolocation_lng, 18, 6)           AS geolocation_lng,
    NULLIF(INITCAP(TRIM(geolocation_city)), '')     AS geolocation_city,
    NULLIF(UPPER(TRIM(geolocation_state)), '')      AS geolocation_state
FROM {{ source('raw', 'raw_geolocation') }}
WHERE TRIM(geolocation_zip_code_prefix) IS NOT NULL