# Baseline Notes

## Root cause

`StringValueFacetCounts` can represent an empty hit set with both count stores unset.
For low-cardinality fields, the constructor leaves `denseCounts` null and depends on
`countOneSegment` to allocate it lazily. When a `FacetsCollector` from a no-match
search has no hits, `count` returns before `countOneSegment` runs. For
high-cardinality fields, the constructor explicitly skips counting on `totalHits == 0`
and also leaves both `denseCounts` and `sparseCounts` null.

The read methods assumed that a null sparse store always meant a non-null dense
store, so `getTopChildren` and related accessors could dereference `denseCounts`
after an empty search and throw `NullPointerException` instead of returning an empty
facet result.

## Files changed

`repo/lucene/facet/src/java/org/apache/lucene/facet/StringValueFacetCounts.java`

- Added a small `hasCountStorage` helper to identify the empty-count state where
  neither sparse nor dense storage was allocated.
- Added an `emptyResult` helper that returns a zero-count `FacetResult` for the
  valid field when no facet values were counted.
- Guarded `getAllChildren` and `getTopChildren` so no-hit collectors return an empty
  result with `childCount == 0`.
- Guarded `getSpecificValue` so an indexed term with no matching hits reports count
  `0`, while a term absent from the field still reports `-1`.

## Assumptions and alternatives

- I treated the field itself as a valid dimension even when the query matched no
  documents, matching the existing behavior of this class and the issue expectation
  that `getTopChildren` should return a result with zero children rather than null.
- I assumed no count storage together with `totalDocCount == 0` is a legitimate
  empty-result state, not an error. This matches the high-cardinality constructor
  branch that intentionally avoids allocating counters for `totalHits == 0`.
- I considered allocating a dense zero-filled array for no-hit searches, but rejected
  that because it would undo the high-cardinality memory optimization and is not
  needed to produce correct zero-count results.
- I did not change `FacetsCollectorManager` or `FacetsCollector`; the failure is in
  `StringValueFacetCounts` assuming storage exists after valid empty collection
  results.
