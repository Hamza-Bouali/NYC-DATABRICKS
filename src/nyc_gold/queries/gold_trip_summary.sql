CREATE OR REPLACE VIEW nyc_taxi.gold.gold_trip_summary
AS
SELECT
  -- Date dimension keys
  DATE(s.pickup_datetime) AS trip_date,
  d.year,
  d.month,
  d.month_name,
  d.day_of_week,
  d.day_name,
  d.is_weekend,
  d.quarter,
  d.is_us_holiday,

  -- Time attributes
  HOUR(s.pickup_datetime) AS pickup_hour,
  CASE 
    WHEN HOUR(s.pickup_datetime) BETWEEN 6 AND 9 THEN 'Morning Rush'
    WHEN HOUR(s.pickup_datetime) BETWEEN 10 AND 15 THEN 'Midday'
    WHEN HOUR(s.pickup_datetime) BETWEEN 16 AND 19 THEN 'Evening Rush'
    WHEN HOUR(s.pickup_datetime) BETWEEN 20 AND 23 THEN 'Night'
    ELSE 'Late Night'
  END AS time_of_day,

  -- Zone dimension keys
  pu.zone_key AS pickup_zone_key,
  pu.borough AS pickup_borough,
  pu.zone_name AS pickup_zone,
  pu.region_group AS pickup_region_group,
  pu.zone_type AS pickup_zone_type,
  pu.is_manhattan AS pickup_is_manhattan,

  do.zone_key AS dropoff_zone_key,
  do.borough AS dropoff_borough,
  do.zone_name AS dropoff_zone,
  do.region_group AS dropoff_region_group,

  -- Measures
  s.trip_duration_minutes,
  s.trip_distance,
  s.passenger_count,
  s.fare_amount,
  s.extra,
  s.mta_tax,
  s.improvement_surcharge,
  s.tip_amount,
  s.tolls_amount,
  s.total_amount,
  s.fare_per_mile,
  s.tip_percentage,

  -- Degenerate dimensions
  s.payment_type,
  CASE s.payment_type
    WHEN 1 THEN 'Credit card'
    WHEN 2 THEN 'Cash'
    WHEN 3 THEN 'No charge'
    WHEN 4 THEN 'Dispute'
    WHEN 5 THEN 'Unknown'
    WHEN 6 THEN 'Voided trip'
  END AS payment_type_name,

  s.rate_code_id,
  CASE s.rate_code_id
    WHEN 1 THEN 'Standard rate'
    WHEN 2 THEN 'JFK'
    WHEN 3 THEN 'Newark'
    WHEN 4 THEN 'Nassau or Westchester'
    WHEN 5 THEN 'Negotiated fare'
    WHEN 6 THEN 'Group ride'
  END AS rate_type_name,

  -- Flags
  s.anomaly_flag

FROM nyc_taxi.silver.green_taxi s
LEFT JOIN nyc_taxi.gold.gold_dim_date d
  ON DATE(s.pickup_datetime) = d.date_key
LEFT JOIN nyc_taxi.gold.gold_dim_zone pu
  ON s.PULocationID = pu.zone_key
LEFT JOIN nyc_taxi.gold.gold_dim_zone do
  ON s.DOLocationID = do.zone_key;