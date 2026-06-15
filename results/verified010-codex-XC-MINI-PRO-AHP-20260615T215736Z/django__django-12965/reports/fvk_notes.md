# FVK Notes

Status: constructed, not machine-checked. No tests, Python, Django code, `kompile`, `kast`, or `kprove` were run.

## Source decisions

### Changed V1 alias initialization

Decision: revise `SQLDeleteCompiler.single_alias` so it calls `get_initial_alias()` whenever all alias refcounts are zero, not only when `alias_map` is empty.

Trace: `fvk/FINDINGS.md` F1 and `fvk/PROOF_OBLIGATIONS.md` PO2-PO4.

Reason: V1 fixed the concrete `Model.objects.all().delete()` state where `alias_map` is empty, but it did not match the existing compiler setup invariant in `SQLCompiler.setup_query()`: a query with no active aliases should have its base alias initialized before alias counting. V2 uses that same invariant, so both empty and inactive alias maps normalize to one active base alias before the single-table decision.

### Added `extra_tables` exclusion

Decision: revise `SQLDeleteCompiler.single_alias` so it returns true only when `active_alias_count == 1 and not self.query.extra_tables`.

Trace: `fvk/FINDINGS.md` F2 and `fvk/PROOF_OBLIGATIONS.md` PO5-PO6.

Reason: V1 ignored `query.extra_tables`. Static source audit showed `get_from_clause()` appends `extra_tables`, while `_as_sql()` emits no additional `FROM` clause beyond the delete target. Therefore `extra_tables` cannot be safely classified as direct single-table delete by this branch. V2 keeps such queries on the existing fallback path.

### Kept the fix in the base delete compiler

Decision: keep the fix in `repo/django/db/models/sql/compiler.py`, not in `QuerySet.delete()`, `_raw_delete()`, or the MySQL backend subclass.

Trace: `fvk/FINDINGS.md` F3 and `fvk/PROOF_OBLIGATIONS.md` PO1 and PO7.

Reason: The public issue and hint identify a backend-neutral SQL generation regression for single-alias deletes. The base `SQLDeleteCompiler.single_alias` property is the existing abstraction consumed by both the default delete compiler branch and the MySQL subclass. Changing it fixes the reported all-delete case while preserving backend-specific fallback handling.

### Left public API and tests unchanged

Decision: no public signatures, return types, or test files were changed.

Trace: `fvk/PROOF_OBLIGATIONS.md` PO8 and `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.

Reason: The needed behavior change is internal to SQL branch selection. The task forbids modifying tests, and the constructed proof is not machine-checked, so no test removal is justified.

## Artifact decisions

The requested artifacts are present:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

Additional FVK adequacy and formal-core artifacts are also present because the FVK instructions require them:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
- `fvk/mini-django-delete.k`
- `fvk/django-delete-spec.k`

The K artifacts model the disputed observable, direct delete versus fallback, over active alias count and extra-table presence. This is sufficient for the reported SQL-shape regression but does not prove SQL quoting, parameter binding, row counts, or backend-specific syntax.
