WITH deduped AS (
    SELECT
        TRIM(review_id)                                                          AS review_id,
        TRIM(order_id)                                                           AS order_id,
        TRY_TO_NUMBER(review_score)                                              AS review_score,
        NULLIF(TRIM(review_comment_title), '')                                   AS review_comment_title,
        NULLIF(TRIM(review_comment_message), '')                                 AS review_comment_message,
        TRY_TO_TIMESTAMP_NTZ(review_creation_date, 'YYYY-MM-DD HH24:MI:SS')     AS review_creation_date,
        TRY_TO_TIMESTAMP_NTZ(review_answer_timestamp, 'YYYY-MM-DD HH24:MI:SS')  AS review_answer_timestamp,
        ROW_NUMBER() OVER (
            PARTITION BY TRIM(review_id)
            ORDER BY TRY_TO_TIMESTAMP_NTZ(review_answer_timestamp, 'YYYY-MM-DD HH24:MI:SS') DESC
        ) AS row_num
    FROM {{ source('raw', 'raw_order_reviews') }}
    WHERE TRIM(review_id) IS NOT NULL AND TRIM(order_id) IS NOT NULL
)
SELECT
    review_id, order_id, review_score, review_comment_title,
    review_comment_message, review_creation_date, review_answer_timestamp
FROM deduped
WHERE row_num = 1