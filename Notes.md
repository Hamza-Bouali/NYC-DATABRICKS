# Data Quality Notes: Trip Dataset

## 1. Choosing a Primary Key

### Initial approach
The combination of pickup and dropoff coordinates was initially chosen as the primary key for the dataset. The reasoning was straightforward: every ride should have a unique pickup/dropoff pair, so this combination seemed sufficient to uniquely identify each record and prevent duplication.

### The problem
Using a sample of data from July 2020, data cleaning revealed that multiple rides shared the same pickup and dropoff coordinates. In other words, the pickup/dropoff combination was **not** always unique.

To find a better key, `total_amount` was added to the combination, which brought cardinality up to 100%. This was puzzling at first — why would the same pickup and dropoff coordinates be associated with different prices?

Further investigation showed the answer: for some rides, the same trip appeared twice in the dataset, once with a positive price and once with a negative price. This pattern is consistent with the following hypothesis:

> The vendor issued a refund by creating a negative transaction, while the original (positive) transaction remained in the dataset — resulting in two records for the same ride.

This is supported by the payment type breakdown: most negative-priced trips have `payment_type = 4` ("No charge") or `payment_type = 3` ("Dispute"), which aligns with refunds or disputed charges. However, a small number of negative-priced records have `payment_type = 1` or `2` (credit card / cash), which don't fit this explanation and remain unresolved.

### Resolution
For now, the dataset was filtered to include only rides with positive pricing information. This allows the pickup/dropoff coordinate combination to serve as the primary key again. A new column, `is_reversed`, was added to flag whether a ride was refunded, so this can be revisited in future analysis.

---

## 2. Zero-Mile Trip Distances

During quality checks, a number of rides were found with a `trip_distance` of zero — which shouldn't happen in practice unless the ride started and ended almost immediately.

Checking the timestamps of these rides showed that many lasted several minutes, or even hours, ruling out "instant" trips as the explanation.

### Initial breakdown

| total_zero_trips | same_location_count | same_location_pct | same_time_count | same_time_pct | same_loc_and_time_count | same_loc_and_time_pct | same_loc_diff_time_count | same_loc_diff_time_pct |
|---|---|---|---|---|---|---|---|---|
| 4,414 | 2,070 | 46.90% | 2,043 | 46.28% | 1,633 | 37.00% | 437 | 9.90% |

For the rows where both location and time matched (`same_loc_and_time`), the working hypothesis is that these are likely system errors or glitches during data collection.

### Deeper breakdown by category and payment type

| Issue Category | Payment Type | Trip Count | % of Category | Avg Fare | Avg Total |
|---|---|---|---|---|---|
| All Zero Trips (Baseline) | 1 | 3,009 | 68.17% | $23.66 | $28.47 |
| All Zero Trips (Baseline) | 2 | 970 | 21.98% | $29.70 | $31.71 |
| All Zero Trips (Baseline) | 3 | 155 | 3.51% | $12.43 | $14.52 |
| All Zero Trips (Baseline) | 4 | 36 | 0.82% | $23.50 | $25.57 |
| All Zero Trips (Baseline) | 5 | 244 | 5.53% | $26.37 | $30.81 |
| High Fare (>$50) | 1 | 198 | 55.15% | $76.14 | $83.10 |
| High Fare (>$50) | 2 | 129 | 35.93% | $163.74 | $165.17 |
| High Fare (>$50) | 3 | 12 | 3.34% | $85.83 | $88.00 |
| High Fare (>$50) | 4 | 7 | 1.95% | $92.86 | $95.50 |
| High Fare (>$50) | 5 | 13 | 3.62% | $60.83 | $67.73 |
| Same Loc + Zero Duration | 1 | 996 | 60.99% | $23.59 | $29.00 |
| Same Loc + Zero Duration | 2 | 492 | 30.13% | $40.46 | $42.25 |
| Same Loc + Zero Duration | 3 | 116 | 7.10% | $12.46 | $14.67 |
| Same Loc + Zero Duration | 4 | 27 | 1.65% | $19.63 | $22.00 |
| Same Loc + Zero Duration | 5 | 2 | 0.12% | $6.51 | $8.76 |
| Toll on Zero Distance | 1 | 224 | 88.89% | $40.31 | $49.32 |
| Toll on Zero Distance | 2 | 8 | 3.17% | $15.08 | $24.89 |
| Toll on Zero Distance | 5 | 20 | 7.94% | $37.19 | $47.00 |

It's still unclear whether these zero-distance trips were canceled. This will be checked against the negative-price flag in the quarantined dataset: if a zero-mile trip has a negative price, it's treated as canceled; otherwise, it's treated as a legitimate (if anomalous) trip.

### Next steps
Each zero-mile scenario points to a different possible root cause, and each needs more investigation before drawing firm conclusions. For now, zero-mile trips are being quarantined into a separate dataset for further analysis rather than dropped outright.

---

## 3. Additional Analysis (via Databricks Genie Agent)

### Issue #1: Zero-Distance Trips (Major)

**Status:** ⚠️ Warning — 4,549 trips (4.06% of dataset)
**Impact:** Medium

**Details:**
- Despite existing filtering rules, 4,549 records still have `trip_distance = 0`.
- These trips still carry fares (avg. $25.43) and non-trivial durations (avg. 16.6 minutes).
- **Likely root cause:** GPS or odometer malfunction, or genuine stationary "waiting time" that was billed as a trip.

**Characteristics:**
- Average fare: $25.43 (vs. $18.54 overall)
- Average duration: 16.6 minutes
- Maximum duration: 1,439 minutes (nearly 24 hours)
- Payment types: mostly credit card (type 1) and cash (type 2)

**Recommendations:**
- Flag these trips for manual review.
- Consider a separate category for "waiting time" trips.
- These may represent airport queue waits, traffic delays, or a meter running while the vehicle was stationary.

---

### Issue #2: Extreme Distance Outliers (Critical)

**Status:** 🚨 Critical — 62 trips

**Implausible values detected:**
- Maximum recorded distance: **249,852 miles** (roughly 10 times around the Earth).
- 62 trips recorded at over 100 miles.
- Top outlier: 249,852 miles covered in just 16 minutes.

**Examples of impossible trips:**
- 249,852 mi in 16 min → ~937,695 mph (Mach 1,220)
- 176,074 mi in 53 min → ~199,330 mph (Mach 260)
- 118,988 mi in 20 min → ~357,000 mph (Mach 465)

**Likely root cause:**
- GPS coordinate errors or data corruption.
- Possible decimal-point errors in distance calculation.
- System glitches during data recording.

**Recommendations:**
- Remove or cap trips over 100 miles (roughly the 99.9th percentile).
- Implement data validation at ingestion time.
- Set up alerts for physically impossible speed calculations.

---

### Issue #3: High-Value Fare Outliers

**Status:** ⚠️ Warning — 645 trips

**Details:**
- Fares exceeding $100.
- Maximum fare recorded: $1,618.60.
- Overall average fare: $18.54; standard deviation: $20.99.

**Statistical thresholds:**
- 3σ threshold: $81.50
- Trips beyond the 3σ threshold: 1,207

**Recommendations:**
- Most of these are likely legitimate (airport runs, long-distance trips, tolls).
- Manually review fares above $500.
- Cross-reference against distance and duration before deciding to exclude.

---

## 4. Conclusion

The dataset has significant issues in its continuous variables (distance, fare, duration), and these need to be handled carefully before any downstream analysis. Outliers should not be included in modeling or reporting until they're properly cleaned or flagged.

The plan is to remove outliers using both the **IQR method** and the **Z-score method**, then compare results from the two approaches to decide which is better suited for this dataset.