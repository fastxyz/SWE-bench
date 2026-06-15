# FVK Notes

## Decision

V1 stands unchanged. The FVK audit found no production source defect in the V1 fix.

## Trace to findings and proof obligations

`fvk/FINDINGS.md` F1 confirms the core issue obligation: `execute_sql_flush()` now takes `sql_list` only and uses `self.connection.alias` internally. This discharges `fvk/PROOF_OBLIGATIONS.md` PO1 and PO2.

F1 and F4 together cover preserved behavior. V1 keeps the existing `transaction.atomic(..., savepoint=self.connection.features.can_rollback_ddl)`, cursor acquisition, and ordered `for sql in sql_list: cursor.execute(sql)` loop. This discharges PO3 within the source and within the finite-list K model.

F2 records that visible tests still pass `connection.alias`. That evidence is suspect because it conflicts with the public issue's requested signature. PO5 treats those tests honestly as legacy evidence and the benchmark forbids modifying them, so F2 does not justify a source change.

F3 records the only compatibility caveat: third-party backend overrides cannot be audited from allowed inputs. PO5 discharges the in-repository compatibility obligation because no production override exists and the only production caller was updated. The external-backend risk does not justify retaining a compatibility overload because the issue explicitly asks to drop the argument.

PO4 is discharged by the updated `flush` command call, `connection.ops.execute_sql_flush(sql_list)`. The FVK `FLUSH-COMMAND-CALL` claim models this producer/consumer shape.

PO6 is discharged by process: no tests, Python, or K tooling were run. The K commands are recorded in `fvk/PROOF.md` only as future machine-check commands.

## Source changes in this FVK pass

No source files under `repo/` were changed during the FVK pass. The V1 code remains the final production fix.

## Artifacts produced

The required artifacts are:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

Additional FVK adequacy and formal-core artifacts are:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
- `fvk/mini-django-flush.k`
- `fvk/execute-sql-flush-spec.k`
