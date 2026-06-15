# Intent Spec

Status: constructed, not machine-checked.

## Scope

This FVK pass audits the V1 fix for `django__django-12741`: the changed `DatabaseOperations.execute_sql_flush()` API and the in-repository source caller in the `flush` management command. It is not a proof of all of Django.

## Public intent obligations

I1. `DatabaseOperations.execute_sql_flush()` must have the simplified signature `execute_sql_flush(self, sql_list)`.

I2. The removed `using` argument must be inferred from the bound operations instance as `self.connection.alias`.

I3. Executing a flush must still run each SQL statement in `sql_list` through the operation's own connection cursor, under `transaction.atomic()` with `savepoint=self.connection.features.can_rollback_ddl`.

I4. The `flush` command, after selecting `connection = connections[database]`, must call `connection.ops.execute_sql_flush(sql_list)` without separately passing `database`.

I5. In-repository definitions, overrides, and source call sites of `execute_sql_flush()` must be compatible with the new one-argument API.

I6. Visible in-repository tests that still call `execute_sql_flush(connection.alias, sql_list)` are suspect legacy evidence for this task: they encode the exact redundant argument the issue says to drop. They are not production source and must not be modified in this benchmark.

## Domain assumptions

D1. The operations object is constructed by Django with a database wrapper connection, as in `BaseDatabaseOperations.__init__(self, connection)`.

D2. `self.connection.alias`, `self.connection.features.can_rollback_ddl`, and `self.connection.cursor()` are available on in-domain database wrapper connections.

D3. `sql_list` is a finite sequence of SQL statements produced for flushing by Django's `sql_flush()` path.

D4. The proof is partial correctness over the finite SQL-list model; it does not prove transaction manager implementation correctness or database-side effects beyond the modeled calls.
