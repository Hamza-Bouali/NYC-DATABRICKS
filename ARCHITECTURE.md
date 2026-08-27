# YG-Pipeline v2: NYC Taxi Lakehouse on Databricks

## Overview

This project is a migration and rebuild of **YG-Pipeline**, my first end-to-end
data pipeline, originally built outside Databricks. The goal here is not to
reinvent the use case — it still runs on the **NYC Taxi dataset** — but to
rebuild it natively on the **Databricks platform** (free trial account) as a
hands-on way to learn the lakehouse ecosystem: Auto Loader, Delta Lake,
medallion architecture, Unity Catalog, and native Spark transformations.

The project is scoped intentionally small so the focus stays on learning the
platform mechanics rather than data modeling complexity.

---

## Architecture

### 1. Ingestion Layer

Two ingestion modes, each suited to a different scenario rather than one
being a "backup" for the other:

- **Auto Loader (streaming/incremental)**
  A job simulates an event producer, dropping files into a Databricks-managed
  volume. A second pipeline is triggered by Auto Loader on file arrival,
  handling the continuous incremental load with checkpointing.
- **COPY INTO (batch/backfill)**
  A scheduled job using the same source but triggered manually or on a
  schedule, controlled by a parameter that forces batch-only processing.
  Used for backfills and reconciliation runs — e.g., catching any records
  Auto Loader's checkpoint might have missed — rather than as a redundant
  safety net.

### 2. Transformation Layer — Spark

Originally planned with dbt, transformations were moved to  **Spark**
after learning about **Adaptive Query Execution (AQE)** and how Databricks
optimizes Spark execution specifically. This was a deliberate shift to get
closer to the engine and understand query optimization directly, rather than
through an abstraction layer.

*(Note: dbt and Spark aren't mutually exclusive on Databricks — `dbt-databricks`
compiles dbt models down to Spark SQL. Native Spark is a choice for this
project's learning goals, not a platform limitation.)*

### 3. Storage Layer

- **Medallion architecture** (Bronze → Silver → Gold)
- **Delta Lake** as the table format throughout

These are the two core Databricks technologies driving the whole migration,
so they're used as the default and only storage solution — no
parquet-only or external storage paths.

### 4. Consumption Layer

Two consumption endpoints:

- **Databricks Dashboards** — for exploratory and operational reporting
  (trip volumes, revenue trends, zone-level activity, etc.)
- **ML (Databricks ML / MLflow)** — target use case: **trip duration and
  fare prediction**, using pickup/dropoff zones, time-of-day, and trip
  distance as core features. (Alternative directions considered: demand
  forecasting by zone/hour, or anomaly detection on fares/GPS outliers —
  may revisit later.)

### 5. Governance & Observability Layer

- **Unity Catalog** — governance: access control, data lineage, and
  discovery across all layers.
- **System tables / Lakehouse Monitoring** — observability: job run
  history, pipeline health, and data quality checks. Unity Catalog alone
  covers governance, not full observability, so this layer is paired with
  it rather than replaced by it.

---

## Goals of the Project

- Learn the Databricks ecosystem hands-on using a real-world dataset
- Understand incremental vs. batch ingestion trade-offs
- Get comfortable with Spark's optimizer (AQE) instead of relying on dbt
- Practice medallion-architecture design with Delta Lake
- Build a small ML use case on top of a clean gold layer
- Apply Unity Catalog governance and basic observability practices

## Out of Scope (for now)

- Multi-cloud or production-grade deployment
- Real-time streaming beyond the simulated producer
- Advanced ML (this is a first pass — a single baseline model is enough)
