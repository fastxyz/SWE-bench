# Public Compatibility Audit

Constructed, not machine-checked.

## Changed symbols

- `QuerySet._batched_insert(self, objs, fields, batch_size, ignore_conflicts=False)`
  - Signature: unchanged.
  - Return type/shape: unchanged (`inserted_rows` list).
  - Public status: private helper, called by `QuerySet.bulk_create()`.
  - Compatibility result: pass.

## Public callers and producers

- `QuerySet.bulk_create(self, objs, batch_size=None, ignore_conflicts=False)`
  - Signature: unchanged.
  - Calls `_batched_insert()` for objects with primary keys using all concrete fields.
  - Calls `_batched_insert()` for objects without primary keys using concrete fields excluding `AutoField`.
  - Compatibility result: pass. Computing the cap inside `_batched_insert()` preserves per-field-list calculation for both paths.

- Public code paths that call `bulk_create()` without explicit `batch_size` include auth permission creation, content type creation, and many-to-many relation additions.
  - Compatibility result: pass. `batch_size=None` still uses the compatible backend maximum.

- Public code paths that call `bulk_create(..., ignore_conflicts=...)` include many-to-many relation additions.
  - Compatibility result: pass. The `ignore_conflicts` support check and insert branch are unchanged; only the number of objects per insert is capped.

## Overrides

No override of `_batched_insert()` was found under `repo/django`. No public subclass call signature is affected.
