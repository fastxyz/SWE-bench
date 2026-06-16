# Baseline Notes

## Root cause

SQLite does not allow `ALTER TABLE ... ADD COLUMN` to add a column with a
`UNIQUE` constraint. Django's SQLite schema editor only remade the table when
adding fields that were non-nullable or had an effective default. A nullable
`OneToOneField` has `null=True` and no default, but it still has
`unique=True`, so the SQLite backend fell through to the base schema editor.
The base editor generated `ALTER TABLE ... ADD COLUMN ... UNIQUE ...`, which
SQLite rejects with `OperationalError: Cannot add a UNIQUE column`.

## Files changed

`repo/django/db/backends/sqlite3/schema.py`

Updated `DatabaseSchemaEditor.add_field()` so SQLite remakes the table when the
new field is unique. This routes nullable `OneToOneField` additions through the
existing `_remake_table()` path instead of emitting unsupported SQLite `ALTER
TABLE ADD COLUMN ... UNIQUE` SQL. The nearby comment was updated to document
that both default-bearing fields and unique fields require the remake path.

## Assumptions and alternatives

I assumed the reported `OneToOneField` should be treated like any other
single-column unique field on SQLite, because `OneToOneField` is implemented as
a `ForeignKey` with `unique=True`.

I considered changing the base column SQL generation to omit inline `UNIQUE`
when adding columns and then create a unique index separately. I rejected that
because the failure is specific to SQLite's `ADD COLUMN` restrictions, while the
base schema editor is shared by other backends.

I also considered special-casing only `OneToOneField`, but rejected it because a
nullable `unique=True` field has the same SQLite limitation and should use the
same schema path.
