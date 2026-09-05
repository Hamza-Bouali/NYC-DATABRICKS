# NYC Taxi Operations Intelligence Platform

This project is a Databricks migration of an on-premises NYC Taxi analytics
platform. It turns NYC Taxi and Limousine Commission trip records into governed
data products for fleet operations, finance, compliance, and strategic planning.

## Executive Summary

The platform transforms raw trip records into trusted analytics for fleet
deployment, financial reporting, anomaly detection, and service-quality
monitoring. Automated ingestion, data cleansing, enrichment, aggregation, and
governance replace manual spreadsheet workflows with reusable lakehouse data
products. Fleet managers can identify demand patterns, finance teams can review
borough performance, and compliance teams can investigate unusual fares using a common source of truth.

## Business Problem

NYC taxi operators manage thousands of vehicles across more than 260 zones.
They need reliable answers to four operational questions:

- **Where should vehicles be deployed?** Empty cruising and vehicle clustering
  reduce earnings and increase customer wait times.
- **Which fares need investigation?** Unusual fare, distance, or duration
  patterns may indicate data errors, meter issues, or route anomalies.
- **Can service coverage be demonstrated?** Borough and zone-level reporting
  must be repeatable rather than assembled manually from raw exports.
- **How is the taxi network performing against other mobility providers?**
  Comparing taxi and for-hire vehicle coverage is a planned extension of the
  platform.

## Stakeholders and Value

| Stakeholder             | Information needed                               | Value delivered                                    |
| ----------------------- | ------------------------------------------------ | -------------------------------------------------- |
| Fleet manager           | Demand and revenue by zone and time              | Better vehicle placement and less empty cruising   |
| Finance analyst         | Daily trips, revenue, tips, and revenue per trip | Faster and more consistent reporting               |
| Compliance officer      | Data-quality and service-coverage evidence       | Repeatable investigations and regulatory reporting |
| Operations lead         | Duration, distance, and anomaly trends           | Earlier visibility into service degradation        |
| Strategic planning team | Taxi versus FHV coverage                         | Better incentive, marketing, and market decisions  |

## Data Products

### 1. Trip Summary

A clean, enriched trip-level dataset with timestamps, zones, boroughs,
time-of-day attributes, payment descriptions, derived measures, and anomaly
flags. It gives analysts a reliable starting point for ad hoc questions without
repeating raw-data cleanup.

### 2. Daily Borough Performance

Daily metrics include trip volume, fare revenue, tips, total revenue, average
tip percentage, average duration, average distance, zones with pickups, and
revenue per trip. These metrics support daily operational and finance reviews.

### 3. Zone and Demand Analytics

The gold layer includes zone and borough dimensions that support demand and
revenue analysis by location. An hourly demand heatmap and underserved,
adequate, or saturated classifications are planned next, using the same
enriched trip foundation.

### 4. Service Quality and Anomaly Monitoring

The Silver layer flags extreme distances and high-value fares while filtering
invalid timestamps, negative monetary values, zero-distance trips, and repeated
business keys from analytical outputs. Suspicious records remain available in
the quarantine layer for investigation.

### 5. FHV Competitive Intelligence

Comparison of yellow taxi trips with for-hire vehicle dispatch feeds is a
planned data product. It will compare coverage, volume, and revenue by zone and
date once the FHV source is connected.

## Current Implementation

The current repository implements the NYC Green Taxi pipeline and zone
reference data:

- Raw Parquet files arrive in a Unity Catalog Volume.
- Auto Loader incrementally ingests records into the Bronze layer ( triggered by file arrival).
- Spark notebooks standardize types, derive trip metrics, filter invalid rows,
  and quarantine duplicates and zero-distance trips.
- SQL tasks build Gold dimensions and the trip summary and borough metrics.
- Databricks Asset Bundles deploy and orchestrate the jobs.

FHV ingestion, dashboards, automated role-specific views, retention policies,
and query-level audit reporting are documented target capabilities rather than
completed features in this repository.

## Architecture and Data Flow

| Stage         | What happens                                                                      | Business meaning                                   |
| ------------- | --------------------------------------------------------------------------------- | -------------------------------------------------- |
| Raw ingestion | Trip files and lookup data are collected automatically                            | No repeated manual uploads                         |
| Bronze        | Source data is stored with incremental ingestion and checkpoints                  | Original records remain available for traceability |
| Silver        | Types are standardized; invalid, duplicate, and zero-distance records are handled | Analysts work from trusted records                 |
| Gold          | Dimensions and daily metrics are materialized from Silver                         | Dashboards and reports load quickly                |
| Governance    | Catalog, schema, table, and deployment boundaries are defined in Databricks       | Access and lineage can be managed centrally        |

The project uses a Bronze, Silver, and Gold medallion architecture with Delta
tables in Unity Catalog:

- `nyc_taxi.bronze`: ingested trip and zone data
- `nyc_taxi.silver`: cleaned and enriched trips
- `nyc_taxi.gold`: dimensions, trip summaries, and reporting metrics
- `nyc_taxi.quarantine`: duplicate and zero-distance records retained for review

## Migration From On-Premises

| Previous platform                  | Databricks implementation                                                     |
| ---------------------------------- | ----------------------------------------------------------------------------- |
| ClickHouse analytical tables       | Delta tables governed by Unity Catalog                                        |
| Apache Spark jobs                  | Databricks Spark notebooks and SQL tasks                                      |
| Docker-based execution             | Databricks-managed job compute and SQL Warehouses                             |
| Terraform infrastructure           | Databricks Asset Bundle configuration in`databricks.yml` and `resources/` |
| Manually managed medallion storage | Unity Catalog schemas and Delta Lake                                          |

The migration preserves the original business purpose while consolidating
execution, orchestration, storage, governance, and deployment on Databricks.
The project remains intentionally small and is designed to demonstrate the
lakehouse approach rather than reproduce a production-scale fleet platform.

## Governance and Compliance Direction

The target operating model includes:

- Role-based access for analysts, engineers, and compliance users.
- Masking or exclusion of sensitive driver information when such fields are
  introduced.
- Retention rules for analyst-facing views.
- Reproducible audit evidence showing the data and logic behind a metric.
- Quarantine and data-quality outputs for invalid or suspicious records.

Unity Catalog provides the foundation for these controls. The role-specific
views, retention automation, and full audit workflow remain implementation work
for a production deployment.

## Expected Business Outcomes

The intended outcomes are:

| Metric                  | Current direction                                                  |
| ----------------------- | ------------------------------------------------------------------ |
| Daily revenue reporting | Replace manual spreadsheet assembly with pre-computed Gold metrics |
| Anomaly detection       | Move from periodic sampling to repeatable daily flagging           |
| Compliance reporting    | Produce consistent borough and zone evidence from governed tables  |
| Ad hoc analysis         | Reduce time spent cleaning and joining raw trip files              |
| Fleet deployment        | Provide the foundation for hourly zone demand recommendations      |

Production ROI figures should be measured after dashboards, dispatch feeds,
and operational baselines are connected. The percentages in the business
concept are target outcomes, not measured results from the current repository.

## Repository Structure

- `src/`: Databricks notebooks and Gold SQL queries.
- `resources/`: Databricks job definitions.
- `databricks.yml`: Databricks Asset Bundle configuration and targets.
- `tests/`: Local test configuration.
- `fixtures/`: Test data fixtures.
- `ARCHITECTURE.md`: Detailed technical architecture notes.

## Getting Started

Install the project dependencies with [uv](https://docs.astral.sh/uv/):

```bash
uv sync --dev
```

Authenticate with the [Databricks CLI](https://docs.databricks.com/dev-tools/cli/databricks-cli.html),
then deploy the development target:

```bash
databricks bundle deploy -t dev
```

Run the ETL job:

```bash
databricks bundle run etl_job -t dev
```

Run local tests:

```bash
uv run pytest
```

The production target is available through the same bundle workflow:

```bash
databricks bundle deploy -t prod
```
