# Baseline Notes

## Root cause

SQLite routes most field alterations through table remaking. The shared
`BaseDatabaseSchemaEditor._field_should_be_altered()` compares field
deconstruction kwargs after removing a fixed set of attributes that do not affect
the database schema. `choices` was not in that ignored set, so changing only
`choices` made SQLite treat the field as altered and rebuild the table even
though Django's core SQLite column definition is unchanged.

Other backends already produced no SQL for this scenario because they do not
need SQLite's table-remake path for the same field metadata-only change.

## Changed files

* `repo/django/db/backends/base/schema.py`
  * Moved the existing ignored field attributes from a local list in
    `_field_should_be_altered()` to an overridable `non_database_attrs` class
    attribute.
  * The default set is unchanged, so non-SQLite backends keep the previous
    behavior.

* `repo/django/db/backends/sqlite3/schema.py`
  * Extended SQLite's `non_database_attrs` with `choices`.
  * This makes SQLite's early `alter_field()` no-op check return false for
    choices-only field changes, avoiding unnecessary table creation/copy/drop
    SQL.

## Assumptions

* For Django's core SQLite backend, `choices` is model/form validation metadata
  and does not change the database column definition.
* The intended fix should be backend-specific. The issue discussion noted that
  custom enum fields on other database backends may legitimately derive
  database schema from `choices`.

## Alternatives considered and rejected

* Adding `choices` to the base ignored attribute list globally: rejected because
  it could mask real schema changes for third-party enum-like fields on
  PostgreSQL, MySQL, Oracle, or other backends.
* Duplicating `_field_should_be_altered()` in the SQLite backend: rejected
  because it would copy the base method's deconstruction comparison logic and
  make future changes easier to miss.
