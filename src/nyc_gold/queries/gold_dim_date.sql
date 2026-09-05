CREATE OR REPLACE TABLE nyc_taxi.bronze.gold_dim_date
AS
WITH date_range AS (
  SELECT explode(sequence(DATE('2020-01-01'), DATE('2026-12-31'), INTERVAL 1 DAY)) AS calendar_date
)
SELECT
  calendar_date AS date_key,
  YEAR(calendar_date) AS year,
  MONTH(calendar_date) AS month,
  MONTH(calendar_date) AS month_of_year,
  DATE_FORMAT(calendar_date, 'MMMM') AS month_name,
  DAY(calendar_date) AS day_of_month,
  DAYOFWEEK(calendar_date) AS day_of_week,
  DATE_FORMAT(calendar_date, 'EEEE') AS day_name,
  CASE WHEN DAYOFWEEK(calendar_date) IN (1, 7) THEN TRUE ELSE FALSE END AS is_weekend,
  WEEKOFYEAR(calendar_date) AS week_of_year,
  QUARTER(calendar_date) AS quarter,
  CONCAT('Q', QUARTER(calendar_date), '-', YEAR(calendar_date)) AS quarter_year,
  CASE 
    WHEN calendar_date IN (
      DATE('2024-01-01'), DATE('2024-07-04'), DATE('2024-12-25'),
      DATE('2025-01-01'), DATE('2025-07-04'), DATE('2025-12-25')
    ) THEN TRUE 
    ELSE FALSE 
  END AS is_us_holiday
FROM date_range;
