# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed Symbols

- `GroupByQueryQueryToolChest.getCacheStrategy(...).pullFromCache(boolean).apply(Object)` internal implementation only.

## API and Dispatch

- Method signatures: unchanged.
- Return types: unchanged.
- Cache object serialized by `prepareForCache`: unchanged.
- Cache key construction: unchanged.
- Virtual dispatch shape: unchanged.
- Public callers: no callsite update required because the same `Function<Object, ResultRow>` contract is preserved.

## Result

No compatibility finding. The V1 change is an internal correction to result-row slot selection during result-level cache reads.
