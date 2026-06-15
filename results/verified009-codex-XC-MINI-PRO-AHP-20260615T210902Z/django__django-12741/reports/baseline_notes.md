# Baseline Notes

## Root cause

`DatabaseOperations.execute_sql_flush()` was defined as `execute_sql_flush(self, using, sql_list)`, even though each `DatabaseOperations` instance is already bound to a single database connection. The `using` value duplicated `self.connection.alias`, which meant callers had to pass information the operation could infer from its own connection.

## Changed files

`repo/django/db/backends/base/operations.py`

Changed `execute_sql_flush()` to accept only `sql_list` and use `self.connection.alias` for the surrounding `transaction.atomic()` block. This keeps the transaction on the same database connection used to create the cursor and execute the flush SQL.

`repo/django/core/management/commands/flush.py`

Updated the `flush` command to call `connection.ops.execute_sql_flush(sql_list)` instead of passing the selected database alias separately. The command already resolves `connection = connections[database]`, so the operation can infer the alias from that connection.

## Assumptions and alternatives considered

I assumed the issue is requesting an internal API signature change rather than backward compatibility with the old call shape. I rejected accepting both `(using, sql_list)` and `(sql_list)` because that would preserve the redundant public surface the issue asks to remove and would add unnecessary argument parsing to a small internal helper.

I also assumed no backend-specific override needed updating because the only `execute_sql_flush()` definition under `repo/django` is the base implementation inherited by all database backends.
