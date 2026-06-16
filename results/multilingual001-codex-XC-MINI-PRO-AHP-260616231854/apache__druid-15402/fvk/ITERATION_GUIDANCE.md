# FVK Iteration Guidance

Status: constructed, not machine-checked.

## Decision

V1 stands unchanged after the FVK audit. No additional production edit is justified by the current findings and proof obligations.

## Why V1 Stands

- F1 is addressed by PO-3: the write target advances from `S + 0`, `S + 1`, ... through `S + P - 1`.
- F2 is addressed by PO-2: the loop is bounded by the post-aggregator count instead of an unadvanced iterator.
- F3 is intentionally not converted into a code change because the public issue concerns valid result-level cache entries. Adding new truncated-cache validation would be a broader behavior change outside the recorded intent.
- F4 confirms the fix does not require public API, cache-key, or serialized cache-shape changes.

## Recommended Future Public Tests

Do not modify tests in this benchmark run. For a normal development follow-up, add or keep a result-level cache regression test where a groupBy query has at least two post-aggregators and verify the cached result preserves both values in order.

## Conditional Machine-Check Step

The emitted commands are:

```sh
kompile fvk/mini-java-cache.k --backend haskell
kast --backend haskell fvk/groupby-cache-spec.k
kprove fvk/groupby-cache-spec.k
```

They were not run in this session. Test-removal recommendations should remain conditional on an actual `kprove` result of `#Top`.

## Next Iteration Trigger

Reopen the code only if a new public requirement broadens the cache contract to malformed cache objects, stale cache entries from different query shapes, or a full Java/K proof of the whole `pullFromCache` method rather than the post-aggregator restoration unit.
