# Proof

Status: constructed, not machine-checked.

This proof audits the V1 fix for `django__django-12741`. It is a constructed FVK proof over the mini semantics in `fvk/mini-django-flush.k` and the claims in `fvk/execute-sql-flush-spec.k`. No K tooling was run.

## Claims proved in the model

1. `EXEC-ALL`: for any finite SQL list `SQLS` and prior trace `DONE`, `execAll(SQLS)` terminates with trace `concatSql(DONE, SQLS)`.
2. `EXECUTE-SQL-FLUSH`: for any operations alias `A` and SQL list `SQLS`, `execFlush(SQLS)` terminates with transaction alias `A` and executed trace `SQLS`.
3. `FLUSH-COMMAND-CALL`: for a selected database alias `A` and SQL list `SQLS`, `flushCommand(A, SQLS)` calls the simplified operation and reaches transaction alias `A` with executed trace `SQLS`.

## Symbolic proof sketch

`EXEC-ALL` is a structural circularity over `SqlList`.

- Empty case: `execAll(.SqlList)` rewrites to `.Unit`, then to `.K`; `concatSql(DONE, .SqlList)` simplifies to `DONE`.
- Non-empty case: `execAll(SQL ; REST)` rewrites to `execute(SQL) ~> execAll(REST)`. The `execute(SQL)` rule appends `SQL` to the trace. The circularity hypothesis applies to `REST` after this genuine rewrite step, yielding `concatSql(appendSql(DONE, SQL), REST)`, which is equal to `concatSql(DONE, SQL ; REST)` by the list simplification rules.

`EXECUTE-SQL-FLUSH` composes the atomic-start rule with `EXEC-ALL`.

- `execFlush(SQLS)` rewrites to `beginAtomic(A, CAN) ~> execAll(SQLS) ~> endAtomic`, where `A` is read from `opsAlias`.
- `beginAtomic(A, CAN)` sets `txnAlias` to `A`. There is no rule or syntax position for a caller-supplied `using` argument.
- `EXEC-ALL` executes `SQLS` in order.
- `endAtomic` completes without changing the trace or alias.

`FLUSH-COMMAND-CALL` composes source caller resolution with `EXECUTE-SQL-FLUSH`.

- `flushCommand(A, SQLS)` sets the modeled operations alias to `A` and rewrites to `execFlush(SQLS)`.
- `EXECUTE-SQL-FLUSH` then gives transaction alias `A` and ordered trace `SQLS`.

## Proof-obligation results

- PO1 simplified arity: discharged.
- PO2 alias inference: discharged.
- PO3 ordered SQL execution: discharged in the mini model and by source preservation of the cursor loop.
- PO4 production source caller update: discharged.
- PO5 in-repository compatibility: discharged for production source; visible tests are suspect legacy evidence; external backends are residual risk.
- PO6 honesty gate: discharged.

## Reproduce the machine check later

These commands are intentionally recorded, not executed in this benchmark:

```sh
cd fvk
kompile mini-django-flush.k --backend haskell
kast --backend haskell execute-sql-flush-spec.k
kprove execute-sql-flush-spec.k
```

Expected machine-check result after any syntax repair needed by a real K installation: `#Top` for all claims.

## Test recommendations

No tests were modified.

Conditioned on a future machine check, tests that assert the new one-argument operation behavior would be subsumed for the modeled alias/trace property. Existing visible tests that call `execute_sql_flush(connection.alias, sql_list)` should be kept or updated by maintainers because they currently assert the legacy arity and are outside this benchmark's editable surface.

## Residual risk

This proof is partial correctness over a finite SQL-list model. It does not prove termination for arbitrary Python iterables, database effects, exception behavior, transaction manager correctness, or third-party backend compatibility. Those are outside the public issue's required source change.
