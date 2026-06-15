# Specification

Status: constructed, not machine-checked.

## Target

The target is the V1 implementation of `DatabaseOperations.execute_sql_flush()` and the source call from `django.core.management.commands.flush.Command.handle()`.

The public issue requires a signature and caller-shape change:

```python
def execute_sql_flush(self, sql_list):
    ...
```

The removed database alias argument is not an input to the operation anymore. It is derived from the database connection already stored on the operations object.

## Human-readable contract

For any in-domain `BaseDatabaseOperations` instance `ops` bound to connection `conn` and any finite `sql_list`:

1. `ops.execute_sql_flush(sql_list)` accepts exactly the SQL list as its explicit argument.
2. The transaction opened by the method uses `conn.alias`.
3. The transaction uses `savepoint=conn.features.can_rollback_ddl`.
4. The method obtains a cursor from `conn.cursor()`.
5. The method executes every SQL statement in `sql_list` once, in list order.
6. The `flush` management command calls the method with only `sql_list` after it resolves the selected connection.

## Public intent ledger

The full ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`. Critical entries:

- E1-E3 establish the simplified one-argument method and the `self.connection.alias` inference requirement.
- E4 and E8 establish the updated source call shape.
- E5-E6 establish that the operation can infer the alias from its bound connection.
- E7 is implementation evidence for preserving the transaction, cursor, and list-execution behavior.
- E9 is suspect legacy-test evidence and does not override the issue intent.

## K model summary

The mini semantics in `fvk/mini-django-flush.k` models only the observable property relevant to this issue:

- an operations object has an `opsAlias`;
- `execFlush(SQLS)` opens an atomic block using `opsAlias`, then executes all statements in `SQLS`;
- `execAll(SQLS)` appends each SQL statement to the observed executed list in order;
- `flushCommand(A, SQLS)` resolves the operations alias to `A` and calls `execFlush(SQLS)`.

The model intentionally abstracts away real Python context-manager mechanics, database I/O, exception propagation, and the implementation of `transaction.atomic()`. Those are outside the issue's changed behavior and are recorded as residual trusted base in `fvk/PROOF.md`.

## Preconditions

- The operation has a bound connection with an alias, `features.can_rollback_ddl`, and `cursor()`.
- `sql_list` is finite.
- The selected `flush` command database alias maps to the connection whose `ops` object is called.

## Postconditions

- The explicit method arity is one argument after `self`: `sql_list`.
- The transaction alias equals the bound connection alias.
- The executed SQL trace equals `sql_list` in the same order.
- The `flush` command source caller uses the one-argument operation call.
