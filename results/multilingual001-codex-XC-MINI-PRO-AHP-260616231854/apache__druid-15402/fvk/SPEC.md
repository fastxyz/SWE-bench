# FVK Spec: apache__druid-15402

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## Verification Target

The audited unit is the groupBy result-level cache producer/consumer path in `GroupByQueryQueryToolChest`:

- `prepareForCache(true)` serializes a `ResultRow` into an ordered cache list.
- `pullFromCache(true)` deserializes that cache list into a `ResultRow`.
- The changed code is the post-aggregator restoration loop in `pullFromCache(true)`.

The formal model intentionally preserves the property axis involved in the bug: the order and destination positions of multiple post-aggregator values.

## Intent Spec

I1. For a valid result-level cache entry created for a groupBy query, `pullFromCache(true)` must restore every post-aggregator metric into the corresponding post-aggregator result-row slot.

I2. The mapping is ordered: the value written by `prepareForCache(true)` for post-aggregator index `i` must be restored at `query.getResultRowPostAggregatorStart() + i`.

I3. The fix must preserve existing dimensions, aggregators, timestamp handling, result-row layout, and public API shape.

I4. Behavior for malformed or truncated cache objects is outside the public issue's required repair. The proof domain is valid cache objects produced under the same query shape and result-level-cache flag.

## Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "whole-query cache for groupBy queries with multiple post-aggregation metrics is broken" | Multiple post-aggregator metrics are in-domain and must all survive result-level cache round-trip. | Encoded in I1 and PO-4. |
| E2 | `benchmark/PROBLEM.md` | No-cache result has `a2 = 21032`, `a3 = 31548`; cache result has `a2 = 31548`, `a3 = NULL`. | The bug is slot-specific: later post-aggregator values must not overwrite earlier post-aggregator slots, and later slots must not remain null. | Encoded in I2 and F1. |
| E3 | `benchmark/PROBLEM.md` hint | "restoring all postaggs into the same index during pullFromCache" | `pullFromCache(true)` must advance the post-aggregator destination index. | Encoded in PO-2 and PO-3. |
| E4 | `GroupByQueryQueryToolChest.prepareForCache` | Result-level cache loop appends `query.getPostAggregatorSpecs().size()` values using `resultRow.get(inPos++)`. | The cache post-aggregator suffix is ordered by post-aggregator index. | Encoded in PO-1. |
| E5 | `GroupByQuery` row layout methods | `getResultRowPostAggregatorStart()` returns aggregator start plus aggregator count; row size with post-aggregators is the signature size. | Post-aggregator index `i` belongs at `postAggregatorStart + i`. | Encoded in PO-2 and PO-4. |
| E6 | `ResultRow.create` | Rows are initialized with nulls. | Unwritten post-aggregator slots remain null, matching the reported symptom and requiring all slots to be written. | Encoded in F1. |
| E7 | Current V1 code | The loop condition is `postPos < query.getPostAggregatorSpecs().size() && results.hasNext()` and the write uses `postPos++`. | The candidate implementation matches the intended count-bounded, advancing loop. | Checked by PO-2 and PO-3, not used as intent by itself. |

## Domain and Preconditions

Let:

- `P = query.getPostAggregatorSpecs().size()`
- `S = query.getResultRowPostAggregatorStart()`
- `V[i]` be the `i`th cached post-aggregator value, for `0 <= i < P`
- `R` be the result row created by `pullFromCache(true)`

The proof domain is:

- `isResultLevelCache == true`
- the cache object has the shape emitted by `prepareForCache(true)` for the same query: timestamp, dimensions, aggregators, then exactly `P` post-aggregator values
- the `ResultRow` allocated by `pullFromCache(true)` has size at least `S + P`

## Formal Claims

C1. Producer shape: `prepareForCache(true)` appends post-aggregator values in index order. For every `i` with `0 <= i < P`, the cache post-aggregator suffix at index `i` equals the source row value at `S + i`.

C2. Restore loop invariant: after `k` iterations of the post-aggregator restore loop, where `0 <= k <= P`, `postPos == k` and every `j < k` has `R[S + j] == V[j]`.

C3. Restore loop step: if `k < P`, the next iteration writes `V[k]` to `R[S + k]` and advances `postPos` to `k + 1`, preserving C2.

C4. Restore loop exit: when `k == P`, all post-aggregator values have been restored, so for every `i` with `0 <= i < P`, `R[S + i] == V[i]`.

C5. Composition: under the valid-cache precondition, the post-aggregator segment of `pullFromCache(true)(prepareForCache(true)(row))` equals the original row's post-aggregator segment.

C6. Frame condition: the V1 change does not alter timestamp, dimension, aggregator restoration, cache-key construction, public method signatures, or segment-level-cache behavior.

## K Artifacts

The reduced K model is in:

- `fvk/mini-java-cache.k`
- `fvk/groupby-cache-spec.k`

The model isolates the post-aggregator loop and cache suffix because that is the smallest property-complete fragment that distinguishes the reported failing behavior (`[a2, a3]` restored as `[a3, null]`) from the intended behavior (`[a2, a3]` restored as `[a2, a3]`).
