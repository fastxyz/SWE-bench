# Formal Spec English

Status: constructed, not machine-checked.

This file paraphrases the nontrivial K claims in `fvk/execute-sql-flush-spec.k`.

## Claim EXEC-ALL

Starting from a state whose computation is `execAll(SQLS)` and whose executed trace is `DONE`, execution reaches an empty computation and the executed trace becomes `concatSql(DONE, SQLS)`.

Meaning: executing a finite SQL list appends every SQL statement to the execution trace exactly once and in input order.

## Claim EXECUTE-SQL-FLUSH

Starting from a state whose computation is `execFlush(SQLS)`, whose operations alias is `A`, and whose executed trace is empty, execution reaches an empty computation, records transaction alias `A`, and records executed trace `SQLS`.

Meaning: `execute_sql_flush(sql_list)` does not take a caller-supplied alias. It uses the alias on the bound operations instance and executes the provided SQL statements in order.

## Claim FLUSH-COMMAND-CALL

Starting from a state whose computation is `flushCommand(A, SQLS)`, execution reaches an empty computation, sets the operations alias to `A`, records transaction alias `A`, and records executed trace `SQLS`.

Meaning: the `flush` command resolves the selected database connection first and then calls the simplified one-argument flush operation for that connection.

## Frame conditions

The model does not specify database contents, exception behavior, transaction implementation internals, or SQL validity. It specifies only the alias source, method arity shape, and ordered execution trace that changed or needed preservation for this issue.
