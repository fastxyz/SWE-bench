# INTENT SPEC

Status: constructed, not machine-checked.

1. Fixture loading on SQLite must not crash merely because a model table name is
   a SQL keyword.
2. The table operand of `PRAGMA foreign_key_check(<table>)` must be treated as
   an SQL identifier.
3. The table operand of `PRAGMA foreign_key_list(<table>)` must be treated as
   an SQL identifier when violation details are collected.
4. The diagnostic `SELECT` used after a violation must treat table and column
   names as SQL identifiers.
5. The backend-specific identifier quoting operation is
   `self.ops.quote_name()`.
6. The public method signature and caller behavior of `check_constraints()`
   must not change.
7. Test files must not be modified in this benchmark task.
