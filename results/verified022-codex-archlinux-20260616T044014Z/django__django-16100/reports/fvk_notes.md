# FVK Notes

## Decision

V1 stands unchanged.

## Trace to findings and proof obligations

F-1 identifies the original bug: without an atomic block, a valid list-editable POST can partially commit earlier changed-form writes when a later save/log bundle raises. PO-2, PO-3, PO-4, and PO-8 cover the fix: V1 wraps the full changed-form write/log sequence in one transaction, and the constructed K claim `LIST_EDITABLE_FAILURE_ROLLBACK` leaves committed state unchanged for any failure position in the batch.

F-2 confirms the transaction boundary is sufficient for the public issue. The relevant source operations are all inside the block at `repo/django/contrib/admin/options.py:2014-2024`, satisfying PO-1 through PO-6. I did not expand the transaction to all of `changelist_view()` because PO-1 and the public issue constrain the requirement to validated list-editable save processing, and broader wrapping would affect GET, invalid formset rendering, and action paths without evidence that those paths need it.

F-3 confirms compatibility. PO-7 and `PUBLIC_COMPATIBILITY_AUDIT.md` show V1 preserves branch selection, hook order, queryset filtering, messages, redirects, and public method signatures. No source change was needed for compatibility.

F-4/PO-9 records the only residual boundary: external side effects or writes to another database alias inside custom hooks are not rolled back by this transaction. I kept V1 unchanged because this is an application-level transaction boundary shared with existing admin change-form behavior, not a defect in the requested list-editable database transaction handling.

## Artifacts

The required artifacts are under `fvk/`: `SPEC.md`, `FINDINGS.md`, `PROOF_OBLIGATIONS.md`, `PROOF.md`, and `ITERATION_GUIDANCE.md`. I also added the FVK adequacy and formal-core files required by the kit: `INTENT_SPEC.md`, `PUBLIC_EVIDENCE_LEDGER.md`, `FORMAL_SPEC_ENGLISH.md`, `SPEC_AUDIT.md`, `PUBLIC_COMPATIBILITY_AUDIT.md`, `mini-admin-transaction.k`, and `changelist-list-editable-spec.k`.

No tests, Python, or K tooling were run, and no test files were modified.
