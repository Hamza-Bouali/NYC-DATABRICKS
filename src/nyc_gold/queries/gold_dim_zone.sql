CREATE OR REPLACE TABLE nyc_taxi.bronze.gold_dim_zone
AS
SELECT
  LocationID AS zone_key,
  Borough AS borough,
  Zone AS zone_name,
  -- Enrich with logical groupings analysts actually use
  CASE 
    WHEN Borough = 'Manhattan' THEN 'Core'
    WHEN Borough IN ('Brooklyn', 'Queens') THEN 'Outer Borough'
    WHEN Borough = 'Bronx' THEN 'Bronx'
    WHEN Borough = 'Staten Island' THEN 'Staten Island'
    WHEN Borough = 'EWR' THEN 'Airport'
    ELSE 'Unknown'
  END AS region_group,
  CASE 
    WHEN Zone LIKE '%Airport%' OR Zone LIKE '%JFK%' OR Zone LIKE '%LGA%' OR Zone LIKE '%EWR%' THEN 'Airport'
    WHEN Zone LIKE '%Center%' OR Zone LIKE '%Midtown%' OR Zone LIKE '%Downtown%' THEN 'CBD'
    WHEN Zone LIKE '%Residential%' THEN 'Residential'
    ELSE 'Mixed'
  END AS zone_type,
  -- Flag for common analyst filters
  CASE WHEN Borough = 'Manhattan' THEN TRUE ELSE FALSE END AS is_manhattan
FROM nyc_taxi.bronze.bronze_zones;

OPTIMIZE nyc_taxi.bronze.gold_dim_zone ZORDER BY (zone_key);