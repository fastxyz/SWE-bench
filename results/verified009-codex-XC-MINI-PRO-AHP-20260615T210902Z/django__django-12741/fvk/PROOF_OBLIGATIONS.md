# Proof Obligations

Status: constructed, not machine-checked.

## PO1: Simplified method arity

Statement: `DatabaseOperations.execute_sql_flush()` accepts only `sql_list` after `self`; no caller-supplied `using` parameter remains in the source definition.

Evidence: E1, E2.

Discharge: source definition is `def execute_sql_flush(self, sql_list)`. The K `EXECUTE-SQL-FLUSH` claim has no input corresponding to `using`.

Status: discharged by source inspection and K model shape.

## PO2: Alias inference

Statement: the transaction alias used by `execute_sql_flush()` is `self.connection.alias`.

Evidence: E3, E5, E6.

Discharge: V1 uses `transaction.atomic(using=self.connection.alias, savepoint=...)`. The K `EXECUTE-SQL-FLUSH` claim records `txnAlias == opsAlias`.

Status: discharged by source inspection and constructed proof.

## PO3: Preserve ordered SQL execution

Statement: every statement in `sql_list` is executed once, in input order, through the bound connection cursor.

Evidence: E7.

Discharge: V1 preserves `with self.connection.cursor() as cursor` and `for sql in sql_list: cursor.execute(sql)`. The K `EXEC-ALL` claim proves the ordered trace property for finite SQL lists.

Status: discharged in the model; real database effects remain outside the mini semantics.

## PO4: Update production source caller

Statement: in-repository production callers of `execute_sql_flush()` use the simplified one-argument call.

Evidence: E4, E8.

Discharge: `repo/django/core/management/commands/flush.py` calls `connection.ops.execute_sql_flush(sql_list)`. Search found no other production source call site under `repo/django`.

Status: discharged by source inspection and `FLUSH-COMMAND-CALL`.

## PO5: Public compatibility audit

Statement: in-repository overrides and source call sites are compatible with the new signature; conflicting visible tests are classified honestly.

Evidence: E9 and compatibility search.

Discharge: no backend overrides found; source caller updated; visible tests with old arity are recorded as suspect legacy tests and left unchanged per task constraints.

Status: discharged for allowed in-repository production source; external backends remain residual risk.

## PO6: Honesty gate

Statement: no tests, Python, or K tooling are run; proof artifacts contain commands and expected outcomes only.

Evidence: benchmark no-exec rule and FVK verify guidance.

Discharge: this FVK pass emits `kompile`/`kast`/`kprove` commands in `PROOF.md` but does not execute them.

Status: discharged.
