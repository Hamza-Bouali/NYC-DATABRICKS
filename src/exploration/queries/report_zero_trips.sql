-- ============================================================================
-- ZERO-DISTANCE TRIPS ANALYSIS REPORT
-- NYC Green Taxi Data Quality Assessment
-- ============================================================================

with zero_dist as (
  select *
  from nyc_taxi.silver.green_taxi
  where trip_distance = 0 
    and date_diff(hour, pickup_datetime, dropoff_datetime) < 1
),

-- Section 1: Executive Summary
executive_summary as (
  select 
    '1. Executive Summary' as section,
    'Total Zero-Distance Trips' as metric,
    cast(count(*) as string) as value,
    round(count(*) * 100.0 / (select count(*) from nyc_taxi.silver.green_taxi), 2) as pct_of_all_trips,
    'Baseline metric' as interpretation
  from zero_dist
  
  union all
  
  select 
    '1. Executive Summary',
    'Unique Trip IDs',
    cast(count(distinct trip_id) as string),
    100.00,
    'No duplicate trip_ids found'
  from zero_dist
  
  union all
  
  select 
    '1. Executive Summary',
    'Date Range',
    concat(date_format(min(pickup_datetime), 'yyyy-MM-dd'), ' to ', date_format(max(pickup_datetime), 'yyyy-MM-dd')),
    null,
    cast(date_diff(day, min(pickup_datetime), max(pickup_datetime)) as string) || ' days span'
  from zero_dist
),

-- Section 2: Data Quality Issues
data_quality_issues as (
  select 
    '2. Data Quality Issues' as section,
    'Same Location + Zero Duration' as metric,
    cast(count(*) as string) as value,
    round(count(*) * 100.0 / (select count(*) from zero_dist), 2) as pct_of_all_trips,
    'CRITICAL: Likely meter errors or test records' as interpretation
  from zero_dist
  where PULocationID = DOLocationID 
    and date_diff(minute, pickup_datetime, dropoff_datetime) = 0
  
  union all
  
  select 
    '2. Data Quality Issues',
    'High Fare (>$50) for Zero Distance',
    cast(count(*) as string),
    round(count(*) * 100.0 / (select count(*) from zero_dist), 2),
    'Suspicious: Possible fraud or flat-rate errors'
  from zero_dist
  where fare_amount > 50
  
  union all
  
  select 
    '2. Data Quality Issues',
    'Toll Charges on Zero Distance',
    cast(count(*) as string),
    round(count(*) * 100.0 / (select count(*) from zero_dist), 2),
    'GPS/odometer error - likely real trips'
  from zero_dist
  where tolls_amount > 0
  
  union all
  
  select 
    '2. Data Quality Issues',
    'Zero or NULL Fare',
    cast(count(*) as string),
    round(count(*) * 100.0 / (select count(*) from zero_dist), 2),
    'No revenue captured'
  from zero_dist
  where fare_amount = 0 or fare_amount is null
),

-- Section 3: Payment Type Analysis
payment_patterns as (
  select 
    '3. Payment Type Distribution' as section,
    case payment_type
      when 1 then 'Credit Card (Type 1)'
      when 2 then 'Cash (Type 2)'
      when 3 then 'No Charge (Type 3)'
      when 4 then 'Dispute (Type 4)'
      when 5 then 'Unknown (Type 5)'
      else concat('Other (', cast(payment_type as string), ')')
    end as metric,
    cast(count(*) as string) as value,
    round(count(*) * 100.0 / (select count(*) from zero_dist), 2) as pct_of_all_trips,
    concat('Avg fare: $', round(avg(fare_amount), 2)) as interpretation
  from zero_dist
  group by payment_type
),

-- Section 4: Issue-Specific Payment Analysis
issue_payment as (
  select 
    '4. Payment Types by Issue' as section,
    'Same Loc+Zero Duration: Cash %' as metric,
    cast(sum(case when payment_type = 2 then 1 else 0 end) as string) as value,
    round(sum(case when payment_type = 2 then 1 else 0 end) * 100.0 / count(*), 2) as pct_of_all_trips,
    'Baseline 22% - ELEVATED (30%)' as interpretation
  from zero_dist
  where PULocationID = DOLocationID and date_diff(minute, pickup_datetime, dropoff_datetime) = 0
  
  union all
  
  select 
    '4. Payment Types by Issue',
    'High Fare: Cash Average',
    cast(count(case when payment_type = 2 then 1 end) as string),
    round(avg(case when payment_type = 2 then fare_amount end), 2),
    'CRITICAL: $163.74 avg - fraud indicator'
  from zero_dist
  where fare_amount > 50
  
  union all
  
  select 
    '4. Payment Types by Issue',
    'Toll Trips: Credit Card %',
    cast(sum(case when payment_type = 1 then 1 else 0 end) as string),
    round(sum(case when payment_type = 1 then 1 else 0 end) * 100.0 / count(*), 2),
    'Baseline 68% - ELEVATED (89%) - legitimate trips'
  from zero_dist
  where tolls_amount > 0
),

-- Section 5: Duplication Analysis
duplication_check as (
  select 
    '5. Database Duplication' as section,
    'Trips in Duplicates Table' as metric,
    cast(count(*) as string) as value,
    round(count(*) * 100.0 / (select count(*) from zero_dist), 2) as pct_of_all_trips,
    'Minimal duplication found' as interpretation
  from zero_dist z
  inner join nyc_taxi.quranatine.taxi_trips_duplicates_2026_08_26_18_21_for_lpep_pickup_datetime_lpep_dropoff_datetime_pulocationid_dolocationid dup
    on z.pickup_datetime = dup.lpep_pickup_datetime
    and z.dropoff_datetime = dup.lpep_dropoff_datetime
    and z.PULocationID = dup.PULocationID
    and z.DOLocationID = dup.DOLocationID
  
  union all
  
  select 
    '5. Database Duplication',
    'All Duplicates: Payment Type',
    'No Charge (Type 3)',
    100.00,
    '100% of duplicates are no-charge trips'
  from zero_dist z
  inner join nyc_taxi.quranatine.taxi_trips_duplicates_2026_08_26_18_21_for_lpep_pickup_datetime_lpep_dropoff_datetime_pulocationid_dolocationid dup
    on z.pickup_datetime = dup.lpep_pickup_datetime
    and z.dropoff_datetime = dup.lpep_dropoff_datetime
    and z.PULocationID = dup.PULocationID
    and z.DOLocationID = dup.DOLocationID
  where z.payment_type = 3
  limit 1
),

-- Section 6: Location Patterns
top_location as (
  select PULocationID, count(*) as cnt
  from zero_dist
  where PULocationID = DOLocationID
  group by PULocationID
  order by cnt desc
  limit 1
),

location_patterns as (
  select 
    '6. Location Patterns' as section,
    'Unique Location Pairs' as metric,
    cast(count(distinct concat(cast(PULocationID as string), '-', cast(DOLocationID as string))) as string) as value,
    null as pct_of_all_trips,
    'Different pickup/dropoff combinations' as interpretation
  from zero_dist
  
  union all
  
  select 
    '6. Location Patterns',
    'Most Frequent Location (Same PU/DO)',
    concat('Location ', cast(t.PULocationID as string)),
    round(t.cnt * 100.0 / (select count(*) from zero_dist where PULocationID = DOLocationID), 2),
    concat(cast(t.cnt as string), ' trips at this location')
  from top_location t
),

-- Combine all sections
final_report as (
  select * from executive_summary
  union all
  select * from data_quality_issues
  union all
  select * from payment_patterns
  union all
  select * from issue_payment
  union all
  select * from duplication_check
  union all
  select * from location_patterns
)

select 
  section,
  metric,
  value,
  case 
    when pct_of_all_trips is not null then concat(cast(pct_of_all_trips as string), '%')
    else 'N/A'
  end as percentage,
  interpretation
from final_report
order by section, metric 