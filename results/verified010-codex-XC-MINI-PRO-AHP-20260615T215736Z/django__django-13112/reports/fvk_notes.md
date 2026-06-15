# FVK Notes

Status: constructed, not machine-checked. I did not run tests, Python, `kompile`, or `kprove`.

## Decision

V1 stands unchanged. The only production source edit remains the existing change in `repo/django/db/models/fields/related.py`.

## Trace to findings and obligations

- Kept the V1 `ForeignObject.deconstruct()` change because `fvk/FINDINGS.md` F1 is exactly discharged by `fvk/PROOF_OBLIGATIONS.md` PO1 and PO2: `DJ_RegLogin.Category` now serializes to `DJ_RegLogin.category`.
- Made no change to the concrete-model branch because F2 and PO3 show `_meta.label_lower` already preserves app-label case while using the lowercase model key.
- Made no change to swappable handling because F3 and PO5 show `SettingsReference` wraps the computed `to` value without recomputing or lowercasing it.
- Did not broaden the fix to `django/db/migrations/operations/utils.resolve_relation()` because F4, PO4, and PO6 localize the reported crash to `Field.clone()` and `ForeignObject.deconstruct()` during `StateApps` rendering. That utility is noted as a possible separate audit item, not a blocker for this issue.

## Artifacts produced

The required artifacts are `fvk/SPEC.md`, `fvk/FINDINGS.md`, `fvk/PROOF_OBLIGATIONS.md`, `fvk/PROOF.md`, and `fvk/ITERATION_GUIDANCE.md`.

To satisfy the FVK method's formal-core and adequacy requirements, I also added `fvk/mini-python.k`, `fvk/related-deconstruct-spec.k`, `fvk/INTENT_SPEC.md`, `fvk/PUBLIC_EVIDENCE_LEDGER.md`, `fvk/FORMAL_SPEC_ENGLISH.md`, `fvk/SPEC_AUDIT.md`, and `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.

## Residual risk

The proof is constructed but not machine-checked. The emitted commands in `fvk/PROOF.md` must be run in an environment with K installed before treating any test as proof-subsumed.

