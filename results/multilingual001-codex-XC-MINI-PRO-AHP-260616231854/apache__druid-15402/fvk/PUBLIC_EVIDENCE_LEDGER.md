# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Source | Quoted or cited evidence | Obligation |
| --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "whole-query cache for groupBy queries with multiple post-aggregation metrics is broken" | Multiple post-aggregator metrics must round-trip through result-level cache. |
| E2 | `benchmark/PROBLEM.md` | Cache result moved `a3` into `a2` and left `a3` null. | Values must be restored into distinct ordered slots. |
| E3 | `benchmark/PROBLEM.md` hint | "restoring all postaggs into the same index during pullFromCache" | The restore loop must advance the destination index. |
| E4 | `GroupByQueryQueryToolChest.prepareForCache` | The result-level-cache branch appends one value per post-aggregator using `inPos++`. | Producer order is post-aggregator spec order. |
| E5 | `GroupByQuery` row layout methods | Post-aggregators start after dimensions and aggregators. | Destination slot for post-aggregator `i` is `postAggregatorStart + i`. |
| E6 | `ResultRow.create` | New rows are initialized with nulls. | Failure to write a post-aggregator slot leaves the public null symptom. |
