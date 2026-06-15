# Intent Spec

Status: constructed, not machine-checked.

## Scope

The target is `DatabaseCache._cull()` as reached from database cache writes. The public issue is specifically about database-cache culling raising `'NoneType' object is not subscriptable` after the cutoff query returns no row.

## Required Behavior

I-001. If `connection.ops.cache_key_culling_sql()` returns no cutoff row, `_cull()` must not index into `None` and must not surface the reported TypeError.

I-002. If `CULL_FREQUENCY` is `0`, the existing documented behavior remains: dump the cache when culling is required.

I-003. If `CULL_FREQUENCY` is `1`, the documented ratio `1 / CULL_FREQUENCY` means all current rows selected for culling are removed. The database backend must not implement that by selecting a row at offset `num`, which is past the last row.

I-004. For ordinary culling with a present cutoff row, preserve the existing database strategy: select the first key greater than the `cull_num` smallest keys and delete keys before that cutoff.

I-005. Public compatibility must be preserved: `_cull()` remains an internal helper with the same signature and call shape, and cache `set()`, `add()`, and `touch()` continue to call `_base_set()` as before.

## Domain Assumptions

A-001. `CULL_FREQUENCY` is an integer and is in the documented domain `0` or positive. Negative cull frequencies are not specified by the public docs and are outside this proof.

A-002. The cache table has non-null, unique `cache_key` values, matching the `createcachetable` schema.

A-003. Backend cutoff SQL has the documented meaning when the table is stable: it returns the key at the requested sorted offset if such a row exists, otherwise no row.
