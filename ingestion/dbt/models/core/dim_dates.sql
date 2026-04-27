SELECT
    TO_NUMBER(TO_CHAR(dt, 'YYYYMMDD'))                              AS date_key,
    dt                                                              AS full_date,
    YEAR(dt)                                                        AS year,
    QUARTER(dt)                                                     AS quarter,
    MONTH(dt)                                                       AS month,
    TO_CHAR(dt, 'MON')                                              AS month_name,
    WEEKOFYEAR(dt)                                                  AS week_of_year,
    DAYOFMONTH(dt)                                                  AS day_of_month,
    DAYOFWEEKISO(dt) - 1                                            AS day_of_week,
    TO_CHAR(dt, 'DY')                                               AS day_name,
    CASE WHEN DAYOFWEEKISO(dt) IN (6, 7) THEN TRUE ELSE FALSE END   AS is_weekend
FROM (
    SELECT DATEADD(day, seq4(), '2015-01-01'::DATE) AS dt
    FROM TABLE(GENERATOR(ROWCOUNT => 4018))
)