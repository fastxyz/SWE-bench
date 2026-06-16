# FVK Notes

## Decision

V1 stands unchanged. The audit found no source edit justified by the public issue intent and proof obligations.

## Trace to Findings and Proof Obligations

`fvk/FINDINGS.md` F-001 identifies the original bug: same-table `RenameModel` still reached database-mutating relation and M2M work. `fvk/PROOF_OBLIGATIONS.md` PO-1 discharges this for V1 because `models.py` now returns before `alter_db_table()`, related `alter_field()`, and M2M loops when table names are equivalent.

F-002 records the main alternative interpretation: auto-created M2M column names may be model-name-derived. PO-1 and PO-4 justify keeping V1 unchanged because the public issue explicitly requires a database no-op while state migration behavior remains intact. Adding M2M schema edits would contradict the no-op obligation.

F-003 and PO-3 cover the non-no-op branch. V1 only adds a same-table guard and leaves actual table rename behavior in place, so no compatibility repair is needed.

F-004 confirms that V1's case-insensitive table-equivalence check is intentional because it mirrors `BaseDatabaseSchemaEditor.alter_db_table()`.

F-005 applies to all proof obligations: the proof artifacts are constructed but not machine-checked, and no tests or K tooling were run because the task forbids execution.

## Files Changed in This FVK Pass

No source files under `repo/` were changed in this pass.

Added FVK artifacts under `fvk/`, including the requested `SPEC.md`, `FINDINGS.md`, `PROOF_OBLIGATIONS.md`, `PROOF.md`, and `ITERATION_GUIDANCE.md`, plus the supporting K and adequacy-audit files required by the FVK documentation.

Added this report at `reports/fvk_notes.md`.
