# Findings

Status: constructed, not machine-checked.

## F1: V1 satisfies the issue-level API obligation

Input/state: `connection.ops.execute_sql_flush(sql_list)` on a `BaseDatabaseOperations` instance bound to `connection`.

Observed in V1: the method signature is `execute_sql_flush(self, sql_list)`, and `transaction.atomic()` receives `using=self.connection.alias`.

Expected from public intent: the old `using` argument is dropped and inferred from `self.connection.alias`.

Classification: confirmed fix, no code change required.

Related proof obligations: PO1, PO2, PO3.

## F2: Visible tests still encode the legacy call shape

Input/state: visible tests call `connection.ops.execute_sql_flush(connection.alias, sql_list)`.

Observed in V1: production source no longer supports that arity.

Expected from public intent: callers should pass only `sql_list` because the alias is inferred.

Classification: suspect legacy-test evidence, not a production code bug. The normal next maintenance step would be to update these tests to `connection.ops.execute_sql_flush(sql_list)`, but the benchmark forbids modifying tests.

Related proof obligations: PO1, PO4, PO5.

## F3: External backend overrides cannot be audited from allowed inputs

Input/state: a third-party backend outside this workspace could override `execute_sql_flush(self, using, sql_list)`.

Observed in allowed inputs: no in-repository backend override exists.

Expected from public intent: the API is simplified in the base operation.

Classification: residual compatibility risk outside the allowed evidence set. It does not justify changing V1 because the issue explicitly requests the incompatible signature simplification.

Related proof obligations: PO5.

## F4: Proof is partial and model-scoped

Input/state: real Python context managers, database errors, and SQL validity are not represented in the mini K semantics.

Observed in proof model: alias selection and ordered SQL execution trace are modeled; database I/O and transaction internals are abstracted.

Expected from public intent: only the method signature and alias inference changed; existing database behavior is preserved by retaining the cursor loop and transaction wrapper in source.

Classification: proof scope limitation, not a code bug.

Related proof obligations: PO3, PO6.
