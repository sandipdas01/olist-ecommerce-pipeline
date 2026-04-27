SELECT
    customer_unique_id,
    MAX(customer_zip_code_prefix) AS customer_zip_code_prefix,
    MAX(customer_city)            AS customer_city,
    MAX(customer_state)           AS customer_state
FROM {{ ref('stg_customers') }}
GROUP BY customer_unique_id