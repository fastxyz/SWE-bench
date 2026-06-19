# FVK Notes

## Decisions

D-001: Keep the V1 behavioral fix and refine it into the V2 raw-name-first form.

Trace: FINDINGS F-001 and F-002; proof obligations PO-001, PO-004, and PO-005.

Reason: F-001 shows the original bug is a producer-side type mismatch. PO-001 requires the `columns` part of an explicit-name unique statement to store the raw table name so `references_column()` returns true. F-002 and PO-004 show that using a raw local `table = model._meta.db_table` matches `_create_index_sql()` and backend `_index_columns()` overrides. PO-005 requires wrapping only the SQL-rendered table placeholder, which V2 does with `Table(table, self.quote_name)`.

D-002: Leave `repo/django/db/backends/ddl_references.py` unchanged.

Trace: FINDINGS F-003; proof obligations PO-003 and PO-004.

Reason: `TableColumns.references_column()` already has a clear raw-table-name contract. Accepting both raw strings and `Table` wrappers would hide the producer bug and broaden shared helper behavior without public-intent evidence.

D-003: Treat V1 as behaviorally correct but not the final audited form.

Trace: FINDINGS F-002; proof obligations PO-001 and PO-004.

Reason: V1 satisfied the core true-positive obligation by passing `model._meta.db_table` into `_index_columns()`, but the FVK audit identified the raw-name-first invariant as the cleaner and more compatible statement of the fix. The V2 refactor is targeted to that invariant and does not alter public signatures.

D-004: Do not run tests or K tooling and do not modify tests.

Trace: FINDINGS F-004.

Reason: The task forbids running tests, Python, and K tooling. `fvk/PROOF.md` records the exact commands for a later machine check, and all test recommendations are non-mutating.

## Changed source files

`repo/django/db/backends/base/schema.py`

Changed `_create_unique_sql()` to set `table = model._meta.db_table`, use that raw value for `IndexName`, `_index_columns()`, and `Expressions`, and wrap it with `Table(table, self.quote_name)` only when populating the SQL-rendered `Statement` table part.

## FVK artifacts

The requested artifacts are:

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
- `fvk/mini-ddl-references.k`
- `fvk/schema-unique-spec.k`

