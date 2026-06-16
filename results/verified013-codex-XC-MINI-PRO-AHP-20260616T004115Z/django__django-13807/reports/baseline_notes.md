# Baseline Notes

## Root cause

`loaddata` disables database constraint checks while loading fixtures, then calls
`connection.check_constraints(table_names=table_names)` with raw model
`db_table` names. On SQLite versions using `PRAGMA foreign_key_check`, the SQLite
backend interpolated those raw table names directly into:

- `PRAGMA foreign_key_check(%s)`
- `PRAGMA foreign_key_list(%s)`

When a model table name was also a SQL keyword, such as `order`, SQLite parsed
the name as SQL syntax instead of as an identifier and raised an
`OperationalError` before fixture loading could complete.

## Files changed

- `repo/django/db/backends/sqlite3/base.py`

  Updated the `supports_pragma_foreign_key_check` branch of
  `DatabaseWrapper.check_constraints()` to quote table names with
  `self.ops.quote_name()` before passing them to SQLite PRAGMAs. The diagnostic
  `SELECT` used when reporting a violated foreign key now also quotes the
  primary key column, foreign key column, and table identifier, so the same
  check remains valid if an invalid fixture row is found in a reserved-word
  table.

- `reports/baseline_notes.md`

  Added this task report describing the cause, the source change, and the
  assumptions considered.

## Assumptions and alternatives considered

- I assumed `table_names` contains unquoted model table names because both
  `loaddata` and test database deserialization collect `model._meta.db_table`
  directly before calling `check_constraints()`.
- I used `self.ops.quote_name()` instead of hard-coded backticks or double
  quotes because that matches Django's backend abstraction and existing SQLite
  introspection code for PRAGMA table arguments.
- I kept the change in the SQLite backend rather than changing `loaddata`
  because `check_constraints()` is also called by database creation and schema
  code, and identifier quoting is backend-specific.
- I did not modify test files or run tests/project code because the benchmark
  instructions explicitly disallow both.
