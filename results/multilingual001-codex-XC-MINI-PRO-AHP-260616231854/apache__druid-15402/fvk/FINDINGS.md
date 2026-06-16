# FVK Findings

Status: constructed, not machine-checked. Findings are based on public intent and static source inspection only.

## F1: Pre-V1 cache restore overwrote post-aggregator slots

- Classification: code bug fixed by V1.
- Evidence: public issue E1-E3 and proof obligations PO-2 through PO-4.
- Input: a valid result-level cache object with at least two post-aggregator values, for example `V[0] = COUNT(*) * 2` and `V[1] = COUNT(*) * 3`.
- Observed before V1: each iteration wrote to `postAggregatorStart + 0`; the last cached value overwrote the first post-aggregator slot and later slots remained null.
- Expected: `V[0]` at `postAggregatorStart + 0`, `V[1]` at `postAggregatorStart + 1`, and so on for all post-aggregators.
- Resolution: V1 writes to `postAggregatorStart + postPos++`, discharging PO-2 and PO-3 for valid cache entries.

## F2: Pre-V1 loop bound was tied to an unadvanced iterator

- Classification: code bug fixed by V1.
- Evidence: the original loop checked `postItr.hasNext()` without advancing `postItr`.
- Input: any valid result-level cache entry with one or more post-aggregator values.
- Observed before V1: the post-aggregator loop was effectively bounded by remaining cached values, not by the number of post-aggregator specs.
- Expected: the loop should restore at most the number of post-aggregator specs for the query.
- Resolution: V1 uses `postPos < query.getPostAggregatorSpecs().size()` as the bound, matching PO-2.

## F3: Truncated or malformed cache rows are outside the repaired intent

- Classification: residual assumption, not a new code bug for this issue.
- Evidence: PO-1 and PO-4 are stated over valid cache entries created by `prepareForCache(true)` for the same query shape.
- Input: a cache row with fewer post-aggregator suffix values than `query.getPostAggregatorSpecs().size()`.
- Observed in V1 by static reasoning: the loop stops when `results.hasNext()` is false; the current code does not add a new post-aggregator-specific "ran out" exception.
- Expected for the public issue: valid cache entries round-trip correctly.
- Decision: no source edit was made for malformed-cache validation because there is no public intent evidence requiring a broader cache-corruption behavior change.

## F4: No public compatibility issue surfaced

- Classification: compatibility check passed.
- Evidence: PO-6 and `PUBLIC_COMPATIBILITY_AUDIT.md`.
- Input: public callers of `getCacheStrategy`, `prepareForCache`, and `pullFromCache`.
- Observed in V1: no method signature, return type, cache object shape, or cache-key construction changed.
- Expected: fix the result restoration without changing public APIs or cache producer format.
- Decision: V1 stands without further compatibility edits.

## Proof-Derived Findings

No additional code defect surfaced from the constructed proof obligations. The proof construction specifically checks the reported failing family `P >= 2`, and the same invariant covers all `P >= 0` valid cache entries.
