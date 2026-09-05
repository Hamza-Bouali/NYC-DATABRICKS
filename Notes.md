### the primary keys :

the combo between droppoff and pickup coordinates of the ride was choosen as the primary key for the dataset.

#### why ?:

every ride is unique in terms of its pickup and dropoff coordinates, which makes this combination a suitable primary key. This ensures that each record in the dataset can be uniquely identified by its specific pickup and dropoff locations, preventing any duplication of rides in the dataset.

#### BUUUUUUT ? :

*i started with smaple data from july 2020*
During the data cleaning process, it was observed that there were instances where multiple rides had the same pickup and dropoff coordinates. which means that the combination of pickup and dropoff coordinates was not always unique.

so i started to look for a better primary key that could uniquely identify each ride in the dataset, but after some research and analysis, o realized that only by adding the some pricing information (*'total_amount'*) to the primary key it will increase the cardinality to 100% , it was weird to me , cuz why would the same pickup and dropoff coordinates have different prices ?

after further investigation, it was found that for some rides, the same ride has two differenent price , positive and negative, which means that the same ride was recorded twice in the dataset with different pricing information.

this can be explained by the fact that some rides may have been canceled or refunded, resulting in a negative price for the same ride.

my hypothesis are :  Vendor issued a refund by creating a negative transaction , and the original transaction was still recorded in the dataset, resulting in two records for the same ride with different pricing information.

well i just found out that most negative trips has payment_type = 4 and 3, which are associated with "No charge" and "Dispute" payment types, respectively. This further supports the idea that these negative trips are likely due to refunds or disputes.

but i still have two payment records which are negative but have payment type  1 and 2.

so at the end i quarinted the dataset to only include rides with positive pricing information, which allowed me to use the combination of pickup and dropoff coordinates as the primary key for the dataset .

also i added a new column called 'is_revers' to indicate whether a ride was refunded or not, which will help in future analysis of the dataset.

### Zero mile as trip distance:

while doing same quality checks on the dataset, i found out that there are some rides with zero mile as trip distance, which is not possible in real life.

it would be considerable if these rides were stopped at nearly the same time as they were started, but after checking the timestamps of these rides, it was found that some of them had a duration of several minutes or even hours, which is not possible for a ride with zero distance.

after some analysis here's the result from a first look at the data :

| total_zero_trips | same_location_count | same_location_pct | same_time_count | same_time_pct | same_loc_and_time_count | same_loc_and_time_pct | same_loc_diff_time_count | same_loc_diff_time_pct |
| ---------------- | ------------------- | ----------------- | --------------- | ------------- | ----------------------- | --------------------- | ------------------------ | ---------------------- |
| 4414             | 2070                | 46.90             | 2043            | 46.28         | 1633                    | 37.00                 | 437                      | 9.90                   |

for the same_loc_and_time  rows , my hypothesis is that these rides were likely to be just system errors or glitches in the data collection process.

with further investigation here's what i found out :

| issue_category            | payment_type | trip_count | pct_of_category | avg_fare | avg_total |
| ------------------------- | ------------ | ---------- | --------------- | -------- | --------- |
| All Zero Trips (Baseline) | 1            | 3009       | 68.17           | 23.66    | 28.47     |
| All Zero Trips (Baseline) | 2            | 970        | 21.98           | 29.7     | 31.71     |
| All Zero Trips (Baseline) | 3            | 155        | 3.51            | 12.43    | 14.52     |
| All Zero Trips (Baseline) | 4            | 36         | 0.82            | 23.5     | 25.57     |
| All Zero Trips (Baseline) | 5            | 244        | 5.53            | 26.37    | 30.81     |
| High Fare (>$50)          | 1            | 198        | 55.15           | 76.14    | 83.1      |
| High Fare (>$50)          | 2            | 129        | 35.93           | 163.74   | 165.17    |
| High Fare (>$50)          | 3            | 12         | 3.34            | 85.83    | 88        |
| High Fare (>$50)          | 4            | 7          | 1.95            | 92.86    | 95.5      |
| High Fare (>$50)          | 5            | 13         | 3.62            | 60.83    | 67.73     |
| Same Loc + Zero Duration  | 1            | 996        | 60.99           | 23.59    | 29        |
| Same Loc + Zero Duration  | 2            | 492        | 30.13           | 40.46    | 42.25     |
| Same Loc + Zero Duration  | 3            | 116        | 7.10            | 12.46    | 14.67     |
| Same Loc + Zero Duration  | 4            | 27         | 1.65            | 19.63    | 22        |
| Same Loc + Zero Duration  | 5            | 2          | 0.12            | 6.51     | 8.76      |
| Toll on Zero Distance     | 1            | 224        | 88.89           | 40.31    | 49.32     |
| Toll on Zero Distance     | 2            | 8          | 3.17            | 15.08    | 24.89     |
| Toll on Zero Distance     | 5            | 20         | 7.94            | 37.19    | 47        |

but we don't know if those trips are canceled or not, so i will check with is they have a negative price or not in the quarantined dataset, and if they have a negative price then they are canceled trips, otherwise they are not canceled trips

at the end each of the zero miles will create a new problem and it need more analysis to be sure about the root cause of this issue, and to find a solution to fix it.
for now i will just quarantine the zero mile trips from the dataset, and i will keep them in a separate dataset for further analysis.

### more analysis on the dataset :

using the genie agent on databricks i was able to get better analysis on the dataset :

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

in conclusion , we can say that the dataset has a lot of issues in the continuous variables, and we need to be careful when analyzing the data, and we need to make sure that we are not using any of the outliers in our analysis. therefore we need to clean the dataset and remove the outliers before doing any analysis on the data.

the most standard way of doing that is either using the IQR method or the Z-score method, but in this case we will use the IQR method to remove the outliers from the dataset, and we will also use the Z-score method to remove the outliers from the dataset, and we will compare the results of both methods to see which one is better for our dataset.
