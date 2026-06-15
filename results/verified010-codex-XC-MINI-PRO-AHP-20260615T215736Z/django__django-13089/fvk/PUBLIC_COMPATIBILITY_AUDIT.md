# Public Compatibility Audit

Status: constructed, not machine-checked.

Changed symbol: `django.core.cache.backends.db.DatabaseCache._cull`.

Compatibility result: pass.

The method signature remains `_cull(self, db, cursor, now)`. No public API, cache setting name, database schema, or return type changed. The existing caller `_base_set()` still invokes `_cull(db, cursor, now)` and does not consume a return value. Cache `set()`, `add()`, and `touch()` retain their public call shapes.

Database SQL contract: the existing `connection.ops.cache_key_culling_sql()` hook is still used for normal cutoff-based culling. The change only guards its no-row result and handles the frequency-one all-rows case before asking for a cutoff.
