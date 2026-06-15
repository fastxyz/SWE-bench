# Spec Audit

Status: constructed, not machine-checked.

| Formal item | Intent item | Audit | Rationale |
| --- | --- | --- | --- |
| `EXEC-ALL` says all finite SQL statements are executed in order. | I3, D3 | Pass | Preserves the existing list loop behavior in the method body. |
| `EXECUTE-SQL-FLUSH` says `execFlush(SQLS)` uses `opsAlias` as the transaction alias. | I1, I2 | Pass | Directly matches the issue's `self.connection.alias` instruction. |
| `EXECUTE-SQL-FLUSH` has no formal input corresponding to old `using`. | I1, I2 | Pass | Directly models the requested signature simplification. |
| `FLUSH-COMMAND-CALL` calls `execFlush(SQLS)` after resolving alias `A` onto the connection/ops state. | I4 | Pass | Matches the updated source caller in `flush.py`. |
| K model abstracts Python context managers and database I/O. | D4 | Pass with residual risk | This abstraction preserves the issue-relevant observable but is not a full Python/Django semantics. |
| Visible tests with old arity are not modeled as expected behavior. | I6, E9 | Pass | The tests conflict with the issue intent and are suspect legacy evidence under FVK. |

No formal-English obligation is candidate-derived without public intent support. No fail or ambiguous entries block accepting V1.
