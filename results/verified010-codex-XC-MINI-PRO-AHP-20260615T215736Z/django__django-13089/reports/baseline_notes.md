# Baseline Notes

## Root cause

`DatabaseCache._cull()` counted cache rows and, when the table was above `MAX_ENTRIES`, selected a cutoff cache key with `connection.ops.cache_key_culling_sql()`. The code then immediately used `cursor.fetchone()[0]`.

That assumes the cutoff query always returns a row. It can return no row if the cache table changes between the count and cutoff query, which matches the reported sporadic failure. It also returns no row deterministically when `CULL_FREQUENCY` is `1`, because `cull_num` equals the number of rows and the cutoff query selects with an offset past the last row.

## Changed files

`repo/django/core/cache/backends/db.py`

Adjusted `DatabaseCache._cull()` so it no longer indexes into a missing cutoff row. If the configured cull fraction means all current rows should be removed, it deletes the table contents directly. Otherwise, it fetches the cutoff row and only runs the cutoff delete when a row was returned.

## Assumptions and alternatives

I assumed the safest behavior for an unexpectedly missing cutoff row is to skip the cutoff delete for that cull attempt. The cache remains usable, and a later write can try culling again once the table state is stable.

I considered replacing the cutoff query with a broader delete strategy, but rejected that because the existing backend-specific SQL is already the intended way to identify the culling boundary.

I considered calling `clear()` for every missing cutoff row, but rejected that because a missing row can be caused by concurrent cache changes and clearing all entries would be more destructive than necessary. The direct table delete is used only when `cull_num == num`, where the configured cull fraction indicates that all current rows should be culled.
