# Baseline Notes

## Root cause

For groupBy result-level cache reads, `GroupByQueryQueryToolChest.pullFromCache` restored cached post-aggregator values into a `ResultRow` using `postAggregatorStart + postPos`, but `postPos` was never incremented. The loop also checked a `PostAggregator` iterator that was never advanced. As a result, when a cached groupBy result contained multiple post-aggregator metrics, each cached post-aggregator value was written to the same row position, so later values overwrote earlier ones and the remaining post-aggregator result slots stayed null.

## Files changed

- `repo/processing/src/main/java/org/apache/druid/query/groupby/GroupByQueryQueryToolChest.java`
  - Changed result-level cache post-aggregator restoration to advance the destination position for each cached post-aggregator value.
  - Replaced the unadvanced `PostAggregator` iterator with an index bounded by `query.getPostAggregatorSpecs().size()`, matching the ordered values written by `prepareForCache`.
  - Removed the now-unused `PostAggregator` import.

## Assumptions and alternatives considered

- I assumed the cached post-aggregator values are ordered the same way they are written in `prepareForCache`, directly after dimensions and aggregators. This is consistent with the nearby serialization code and the result-row layout exposed by `getResultRowPostAggregatorStart()`.
- I considered changing the cache key or aggregator restoration logic, but the result-level cache key already includes post-aggregator specs and aggregator values are restored through the shared `CacheStrategy.fetchAggregatorsFromCache` helper. The observed corruption only occurs after aggregator restoration, in the post-aggregator write loop.
- I considered adding new validation for truncated cache rows with fewer post-aggregator values than the query expects. That would be a broader cache-corruption behavior change and is not required to fix the reported overwrite/null result for valid cache entries.
- I did not modify tests or run the test suite because the task instructions reserve tests for hidden evaluation and prohibit running code in this session.
