# 🔍 NYC Green Taxi Dataset - Complete Analysis Report

## Executive Summary

**Dataset:** NYC Green Taxi Trip Records
**Overall Data Quality Score:** 94.7% (18/19 checks passed)

---

## 1. Dataset Overview

* **Bronze Layer:** 112,420 records
* **Silver Layer** : 111,975 records
* **Records Filtered:** 445 (0.40%)
* **Total Columns:** 24 fields in silver layer
* **Primary Key:** `trip_id` (SHA-256 hash of pickup/dropoff times + locations)

---

## 2. ✅ Data Quality Strengths

### Completeness (PASS)

* **Zero null values** in all critical fields:
  * trip_id, vendor_id, pickup_datetime, dropoff_datetime
  * PULocationID, DOLocationID, trip_distance, total_amount

### Uniqueness (PASS)

* **Primary key is 100% unique** - no duplicates in trip_id
* All 111,975 records have unique identifiers

### Validity - Most Checks (PASS)

* ✅ No negative fares or total amounts
* ✅ No trips with duration > 24 hours
* ✅ No trips with duration ≤ 0
* ✅ No passenger counts = 0 or > 6
* ✅ No pickup after dropoff timestamp issues
* ✅ All location IDs within valid range (1-265)

---

## 3. ⚠️ Data Quality Issues Identified

### Issue #1: Zero-Distance Trips (MAJOR)

**Status:** ⚠️ WARNING - 4,549 trips (4.06%)
**Impact:** Medium

**Details:**

* Despite filtering rules, 4,549 records remain with `trip_distance = 0`
* These trips still have fares (avg $25.43) and duration (avg 16.6 minutes)
* **Root Cause:** Likely GPS/odometer malfunction or stationary waiting time

**Characteristics of Zero-Distance Trips:**

* Average fare: $25.43 (vs $18.54 overall)
* Average duration: 16.6 minutes
* Maximum duration: 1,439 minutes (nearly 24 hours!)
* Payment types: Mostly credit card (type 1) and cash (type 2)

**Recommendation:**

* Flag these for manual review
* Consider separate category for "waiting time" trips
* May represent airport queue waits, traffic delays, or meter running while stationary

---

### Issue #2: Extreme Distance Outliers (CRITICAL)

**Status:** 🚨 CRITICAL - 62 trips

**Implausible Values Detected:**

* Maximum distance: **249,852 miles** (could circle Earth 10 times!)
* 62 trips recorded > 100 miles
* Top outlier: 249,852 miles in just 16 minutes

**Examples of Impossible Trips:**

* 249,852 mi in 16 min → 937,695 mph (Mach 1,220)
* 176,074 mi in 53 min → 199,330 mph (Mach 260)
* 118,988 mi in 20 min → 357,000 mph (Mach 465)

**Root Cause:**

* Likely GPS coordinate errors or data corruption
* Possibly decimal point errors in distance calculation
* Could be system glitches during data recording

**Recommendation:**

* **Remove or cap trips > 100 miles** (99.9th percentile)
* Implement data validation at ingestion
* Set up alerts for impossible speed calculations

---

### Issue #3: High-Value Fare Outliers

**Status:** ⚠️ WARNING - 645 trips

**Details:**

* Fares exceeding $100
* Maximum fare: $1,618.60
* Average fare (overall): $18.54
* Standard deviation: $20.99

**Statistical Thresholds:**

* 3σ threshold: $81.50
* Outliers beyond 3σ: 1,207 trips

**Recommendation:**

* Most legitimate (airport runs, long-distance, tolls)
* Review fares > $500 individually
* Cross-reference with distance and duration

---

## 4. Data Transformation Issues

### Records Filtered from Bronze → Silver

**Total Filtered:** 445 records (0.40%)

**Breakdown by Reason:**

1. **Negative Monetary Values** (321 records)

   * Negative total amounts: 321
   * Negative fares: 319
   * *Likely refunds or system errors*
2. **Timestamp Issues** (125 records)

   * Dropoff before/same as pickup: 125
   * Duration ≤ 0: 125
   * *Data entry errors or system clock issues*
3. **Same Pickup/Dropoff Location** (13,263 in bronze)

   * Filtered to prevent circular trips
   * *Many legitimate waiting/queue scenarios removed*
   * **CONCERN:** This may be over-filtering valid data
4. **Zero Distance** (4,790 in bronze)

   * Filter applied but 4,549 remain in silver
   * **CONCERN:** Filter not working correctly

---

## 5. Categorical Data Distributions

### Vendor Distribution

* **Vendor 1:** 13,283 trips (11.9%)
* **Vendor 2:** 95,264 trips (85.1%) - Dominant vendor
* **Vendor 6:** 3,428 trips (3.1%) - ⚠️ Unexpected vendor ID

**Issue:** Vendor ID 6 doesn't match standard NYC TLC vendor codes (1=Creative Mobile, 2=VeriFone)

### Rate Code Distribution

* **Standard Rate (1):** 106,557 (95.2%)
* **JFK (2):** 275 (0.2%)
* **Newark (3):** 61 (0.1%)
* **Nassau/Westchester (4):** 112 (0.1%)
* **Negotiated (5):** 4,967 (4.4%)
* **Group Ride (6):** 3 (0.0%)

### Payment Types

* **Credit Card (1):** 71,611 (64.0%)
* **Cash (2):** 29,615 (26.5%)
* **No Charge (3):** 546 (0.5%)
* **Dispute (4):** 149 (0.1%)
* **Unknown (5):** 10,054 (9.0%)

### Store and Forward Flag

* **No (N):** 101,452 (90.6%)
* **Yes (Y):** 471 (0.4%)
* **Null:** 10,052 (9.0%) - ⚠️ Missing data

### Trip Type

* **Street-hail (1):** 97,259 (86.9%)
* **Dispatch (2):** 4,662 (4.2%)
* **Null:** 10,054 (9.0%) - ⚠️ Missing data

---

## 6. Statistical Summary

### Fare Amount

* Average: $18.54
* Std Dev: $20.99
* Min: $0.00 (free rides or promotions)
* Max: $1,618.60

### Trip Distance

* Average: **22.70 miles** (seems high for NYC taxi)
* Max: **249,852 miles** (data error)
* Realistic max (manual): ~50-100 miles

### Trip Duration

* Average: 20.85 minutes
* 95th percentile: 41 minutes
* 99th percentile: 83.98 minutes
* Max: 1,439.85 minutes (23.99 hours)

---

## 7. 🔍 Key Data Errors Summary

| Error Type                          |  Count | Severity    | Action Required |
| :---------------------------------- | -----: | :---------- | :-------------- |
| Extreme distance outliers (>100 mi) |     62 | 🚨 CRITICAL | Remove/cap      |
| Zero-distance trips with fares      |  4,549 | ⚠️ HIGH   | Flag/review     |
| High fares (>$100)                  |    645 | ⚠️ MEDIUM | Review          |
| Unexpected Vendor ID (6)            |  3,428 | ⚠️ MEDIUM | Investigate     |
| Missing trip_type                   | 10,054 | ⚠️ LOW    | Impute          |
| Missing store_fwd_flag              | 10,052 | ⚠️ LOW    | Impute          |
| 3σ fare outliers                   |  1,207 | ℹ️ INFO   | Monitor         |

---

## 8. 🎯 Recommendations

### Immediate Actions (Critical)

1. **Remove Impossible Distance Values**

   * Filter: `trip_distance <= 100` miles
   * Or cap at 99.9th percentile value
   * Would remove 62 corrupt records
2. **Fix Zero-Distance Filter Logic**

   * Current filter not working correctly
   * 4,549 zero-distance trips remain
   * Review transformation code in Cell 19
3. **Investigate Vendor ID 6**

   * Non-standard vendor code
   * 3,428 trips (3.1% of data)
   * Validate with TLC documentation

### Data Quality Improvements

4. **Add Validation Rules at Ingestion**

   * Speed validation: distance/time < 100 mph
   * Distance cap: < 150 miles (max NYC to distant suburbs)
   * Fare reasonability: $2-$500 range
5. **Handle Missing Values**

   * 10,054 records missing trip_type and store_fwd_flag
   * Impute based on vendor patterns
   * Document imputation strategy
6. **Create Data Quality Monitoring**

   * Real-time alerts for outliers
   * Daily quality score reports
   * Trend analysis dashboard

### Analysis Considerations

7. **Separate Zero-Distance Category**

   * Don't exclude - analyze separately
   * May represent legitimate waiting time
   * Important for driver revenue analysis
8. **Review Same-Location Filter**

   * Currently excludes 13,263 trips
   * May be over-filtering legitimate data
   * Consider: queue waits, U-turns, short pick-up/drop-offs

---

## 9. Data Lineage & Processing

### Bronze Layer

* Source: Parquet files in `/Volumes/nyc_taxi/bronze/raw_data/`
* Schema: 22 columns (raw NYC TLC format)
* Volume: 112,420 records

### Silver Layer

* Target: `nyc_taxi.silver.green_taxi`
* Transformations applied:
  * Type casting (timestamps, integers, doubles)
  * Data cleaning (nulls, negatives)
  * Feature engineering (trip_id, duration, fare_per_mile, tip_percentage)
  * Time-based features (pickup_hour, pickup_day_of_week)
  * Business rule filtering
* Volume: 111,975 records

### Quarantine Layer

* Duplicate records saved to: `nyc_taxi.quarantine` schema
* Includes detailed timestamp for audit trail

---

## 10. Conclusion

**Overall Assessment:** Good quality with targeted issues

**Strengths:**

* Excellent completeness (no nulls in critical fields)
* Perfect uniqueness (no duplicate trips)
* Strong timestamp integrity
* Reasonable monetary values

**Critical Issues:**

* 62 impossible distance values (data corruption)
* 4,549 zero-distance trips need review
* Filter logic not working as intended

**Quality Score: 94.7%** - Good, but requires attention to outliers

**Next Steps:**

1. Apply distance cap/filter (remove 62 corrupt records)
2. Fix zero-distance filter bug
3. Investigate Vendor ID 6
4. Implement monitoring dashboard
5. Document data quality SLAs

---

*Analysis completed: August 29, 2026*
*Data Quality Framework: 5 categories, 19 validation checks*
*Tools: PySpark, Databricks, Delta Lake*
