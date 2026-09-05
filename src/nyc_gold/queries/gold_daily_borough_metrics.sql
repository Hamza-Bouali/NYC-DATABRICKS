CREATE MATERIALIZED VIEW nyc_taxi.gold.daily_borough_metrics
AS
SELECT
  trip_date,
  pickup_borough AS borough,
  COUNT(*) AS total_trips,
  ROUND(SUM(fare_amount), 2) AS total_fare_revenue,
  ROUND(SUM(tip_amount), 2) AS total_tip_revenue,
  ROUND(SUM(total_amount), 2) AS total_revenue,
  ROUND(AVG(tip_percentage), 2) AS avg_tip_pct,
  ROUND(AVG(trip_duration_minutes), 2) AS avg_duration_min,
  ROUND(AVG(trip_distance), 2) AS avg_distance_mi,
  COUNT(DISTINCT pickup_zone) AS zones_with_pickups,
  ROUND(SUM(total_amount) / COUNT(*), 2) AS revenue_per_trip,
  SUM(CASE WHEN anomaly_flag != 'NORMAL' THEN 1 ELSE 0 END) AS anomaly_count
FROM nyc_taxi.gold.trip_summary
GROUP BY trip_date, pickup_borough;