# Architecture Decision Records

This folder records the *why* behind non-obvious technical decisions in this
pipeline  not the what (that's what the code and the main README are for).

## What counts as "ADR-worthy"

Write one when a decision meets at least one of these:

- Someone reviewing the repo could reasonably ask "why this and not X?" and
  the honest answer is more than one sentence.
- You seriously considered more than one approach before picking.
- The decision has a real cost or trade-off attached (not free , everything
  interesting is a trade-off).
- Getting it wrong would be expensive to unwind later (a data model, a
  write strategy, a security boundary , not a variable name).

Don't write one for decisions with an obvious, undisputed answer, or for
implementation details that would just restate the code in prose.

## How to add one

1. Copy `0000-template.md` to `NNNN-short-descriptive-slug.md`, where
   `NNNN` is the next sequential number (check the index below for the
   highest number in use).
2. Fill it in , especially "Consequences." An ADR that only lists upside is
   marketing copy, not a decision record.
3. Add a row to the index table below.
4. Open it as a PR alongside (or shortly after) the code change it
   documents, so reviewers see the reasoning next to the diff.

## Status values

| Status | Meaning |
|---|---|
| Proposed | Written, not yet acted on or still under discussion |
| Accepted | The decision is live in the codebase |
| Superseded by ADR-NNNN | A later decision replaced this one , keep the old file, link forward |
| Deprecated | No longer relevant (e.g., the component it describes was removed) |

Never delete an ADR because it became outdated , mark it Superseded or
Deprecated and let the history stand. The record of a decision that was
later reversed is often more useful in an interview than one that wasn't.

## Index

| ADR | Title | Status |
|---|---|---|
| [0001](0001-ingestion-auto-loader.md) | Use Auto Loader for Bronze ingestion (over COPY INTO / Lakeflow Connect) | Accepted |
| [0002](0002-notebooks-vs-declarative-pipelines.md) | Notebook tasks in DABs vs. Lakeflow Declarative Pipelines | Proposed , needs real rationale before Accepted |
| [0003](0003-write-strategy-per-layer.md) | Write strategy per layer (overwrite / merge / materialized view) | Accepted |
| [0004](0004-anomaly-thresholds-duplicate-keys.md) | Anomaly thresholds and duplicate-key strategy | Proposed , needs real thresholds before Accepted |
| [0005](0005-operational-resilience.md) | Late-arriving records, schema drift, restarts, idempotent reruns | Accepted |

Keep this table current , an ADR folder with a stale index is worse than no
index, since it silently tells reviewers "this hasn't been maintained."
