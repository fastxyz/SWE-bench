# Baseline notes — django__django-12708

## Issue

> Migration crashes deleting an `index_together` if there is a `unique_together`
> on the same fields.

When a model declares both `unique_together` and `index_together` over the *same*
set of fields, running a migration that removes the `index_together` (while keeping
`unique_together`) crashes with:

```
ValueError: Found wrong number (2) of constraints for <table>(<col1>, <col2>)
```

raised in `BaseDatabaseSchemaEditor._delete_composed_index()`
(`django/db/backends/base/schema.py`).

## Root cause

`alter_index_together()` deletes a composed index by calling:

```python
self._delete_composed_index(model, fields, {'index': True}, self.sql_delete_index)
```

`_delete_composed_index()` resolves the concrete constraint name to drop via
`_constraint_names(model, columns, **constraint_kwargs)`, then asserts exactly one
match before issuing the `DROP`.

The problem is the filter `{'index': True}` is **not specific enough**. On the
databases where the bug reproduces (MySQL, SQLite), a `unique_together` constraint
is physically backed by an index, and the introspection layer reports it as *both*
unique and an index:

- MySQL (`django/db/backends/mysql/introspection.py`): the unique constraint is
  marked `unique=True` from `information_schema.table_constraints`, and the same
  named entry is later picked up by `SHOW INDEX` which sets `'index': True`
  (line ~263). Result: `unique=True, index=True`.
- SQLite (`django/db/backends/sqlite3/introspection.py`): `PRAGMA index_list`
  yields the unique index with `unique=True` and `index=True` (lines ~386-394).

So for two fields carrying both a `unique_together` (`*_uniq`) and an
`index_together` (`*_idx`):

| constraint | `unique` | `index` |
|------------|----------|---------|
| `*_uniq`   | True     | True    |
| `*_idx`    | False    | True    |

Filtering with `{'index': True}` matches **both** rows → 2 constraint names →
`ValueError`. (On PostgreSQL the unique constraint keeps `index=False`, so the bug
does not manifest there, but the fix is harmless and still correct.)

The symmetric direction — deleting `unique_together` while `index_together`
remains — already works, because `alter_unique_together()` filters with
`{'unique': True}`, and the `*_idx` index has `unique=False`, so it is excluded
(exactly one match).

## Fix

File changed: `django/db/backends/base/schema.py`, method `alter_index_together()`.

Make the index-deletion filter unambiguous by also requiring the target to be
non-unique:

```python
# Deleted indexes
for fields in olds.difference(news):
    self._delete_composed_index(
        model,
        fields,
        {'index': True, 'unique': False},
        self.sql_delete_index,
    )
```

An `index_together` index is always created as a **non-unique** index (see the
creation path a few lines below: `self._create_index_sql(model, fields,
suffix="_idx")`, which emits no `UNIQUE`), so `unique=False` is always true for the
index we want to drop, and it cleanly excludes the co-located `unique_together`
constraint. The result is exactly one matching constraint name again.

This is the only edit required:

- The MySQL schema override `MySQLSchemaEditor._delete_composed_index()`
  (`django/db/backends/mysql/schema.py`) forwards `*args` unchanged to
  `super()._delete_composed_index()`, so the more specific `constraint_kwargs`
  propagate there automatically.
- `alter_unique_together()` needs no change (its `{'unique': True}` filter already
  excludes the non-unique index).

## Assumptions

- An `index_together`-generated index is always non-unique. This holds: it is
  created via `_create_index_sql(..., suffix="_idx")` with no uniqueness, and there
  is no API to make `index_together` produce a unique index (that is what
  `unique_together` is for).
- Backends that do *not* report a unique constraint as an index (e.g. PostgreSQL)
  are unaffected: the `*_idx` index still satisfies `index=True, unique=False`, so
  the match count stays at one.

## Alternatives considered and rejected

1. **Post-filter the results inside `_delete_composed_index()`** (e.g. drop any
   name that is also a unique constraint when deleting an index). Rejected: the
   caller already knows the precise semantics (`index_together` ⇒ non-unique
   index), so expressing it through `constraint_kwargs` — the mechanism the method
   is designed around — is simpler, more explicit, and keeps `_delete_composed_index`
   generic.

2. **Change the introspection backends so a unique constraint is not reported with
   `index=True`.** Rejected: on MySQL/SQLite a unique constraint genuinely *is*
   backed by an index; other consumers of `_constraint_names`/`get_constraints`
   may legitimately rely on that. This would be a far broader, riskier change for
   a localized problem.

3. **Address issue point 2 ("moving the declaration of an index should not result
   in an index re-creation") in the migration autodetector/optimizer.** Rejected
   as out of scope. That is a separate enhancement about operation ordering; the
   concrete, reproducible crash (point 1) lives in the schema editor. The reporter's
   own hint about the autodetector is explicitly speculative ("I haven't looked
   under the hood on this yet"). The minimal, targeted fix for the crash is the
   schema-editor filter change above.
