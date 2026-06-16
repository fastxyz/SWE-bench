# FINDINGS

Status: FVK audit findings; constructed, not machine-checked.

## F-001: Same-table RenameModel must skip all DB schema work

- Classification: resolved code bug in V1.
- Evidence: `benchmark/PROBLEM.md` says `RenameModel` with `db_table` "should be a noop" and reports FK/table churn.
- Symbolic input: `AllowMigrate = true`, `SameTable = true`, `RelatedCount >= 0`, `M2MCount >= 0`.
- Pre-V1 observed behavior: the direct `alter_db_table()` call could no-op, but execution still reached incoming relation `alter_field()` calls and applicable M2M table/field calls.
- Expected behavior: database-operation count is unchanged.
- V1 status: `repo/django/db/migrations/operations/models.py` lines 323-332 compute old/new table names and return before all database-mutating calls when the table names are equivalent.
- Linked proof obligations: PO-1, PO-6.

## F-002: Auto-created M2M column-renaming concern is under the no-op requirement

- Classification: audited alternative, no V2 code change.
- Evidence: auto-created M2M through field names can be model-name-based, while M2M table names are derived from the owning model table and field name. The issue, however, explicitly requires the `RenameModel` database operation to be a no-op when `db_table` fixes the main table identity.
- Symbolic input: `AllowMigrate = true`, `SameTable = true`, `M2MCount > 0`.
- V1 behavior: no M2M schema operations are emitted.
- Expected behavior under public issue intent: no database operations are emitted.
- Residual risk: public intent does not separately specify post-rename runtime behavior for auto-created M2M column names in this same-table scenario. Adding M2M column edits would contradict the stated database no-op. Keep V1 unless public requirements clarify a different M2M-specific contract.
- Linked proof obligations: PO-1, PO-4.

## F-003: Different-table branch must not regress

- Classification: compatibility obligation, no V2 code change.
- Evidence: public migration tests describe `RenameModel` repointing incoming FKs/M2Ms when the table actually changes.
- Symbolic input: `AllowMigrate = true`, `SameTable = false`, non-negative relation/M2M counts.
- V1 behavior: the early return is not taken, and the pre-existing table, relation, and M2M operations remain in order.
- Expected behavior: operation count follows `1 + RelatedCount + 2 * M2MCount` in the abstract model.
- Linked proof obligations: PO-3, PO-5.

## F-004: Case-insensitive table equivalence should mirror schema editor behavior

- Classification: resolved compatibility detail in V1.
- Evidence: `BaseDatabaseSchemaEditor.alter_db_table()` treats exact equality and backend case-insensitive equality as no-op.
- Symbolic input: `SameTable = true` because backend ignores table-name case and lower-case names match.
- V1 behavior: returns before relation/M2M work.
- Expected behavior: no database operations, matching the table editor's no-op convention.
- Linked proof obligations: PO-1.

## F-005: Formal proof was not machine-checked

- Classification: verification caveat, not a code bug.
- Evidence: task forbids running tests, Python, `kompile`, or `kprove`.
- Impact: proof and K artifacts are constructed only. Test-removal recommendations are therefore none; keep tests until a future machine check returns `#Top`.
- Linked proof obligations: all.
