# Intent Spec

Status: constructed, not machine-checked.

1. A groupBy result-level cache entry with multiple post-aggregator metrics must restore all post-aggregator metric values.
2. Restoration is positional and ordered: post-aggregator value `i` is restored to `query.getResultRowPostAggregatorStart() + i`.
3. The result-level cache fix must not alter timestamp, dimension, aggregator, cache-key, or public API behavior.
4. Valid cache entries produced for the same query shape are in scope. Malformed, truncated, or stale cache entries are out of scope for this issue unless future public intent says otherwise.
