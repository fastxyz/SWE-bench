# FVK Notes

## Decision

V1 stands unchanged. The audit found no source change justified by the FVK findings or proof obligations.

## Trace to Findings and Obligations

* The original bug is captured by F-001 and PO-1/PO-2. V1's `models.JSONField` branch sends non-null JSONField values to `field.formfield().prepare_value(value)`, so dictionary values no longer reach the Python repr fallback.
* F-002 and PO-3 justify keeping delegation to `prepare_value()` rather than replacing it with a direct `json.dumps()` call. This preserves `InvalidJSONInput`.
* F-003 and PO-4 justify the `isinstance(field, models.JSONField)` check. It satisfies the public hint by covering inheritance, including `django.contrib.postgres.fields.JSONField`, without coupling admin to postgres.
* F-004 and PO-5 justify keeping the JSONField branch after `value is None`. Existing admin behavior treats `None` as `empty_value_display`, and the public issue does not override that contract.
* F-005 and PO-7 justify making no API-level edits. The public helper signature and existing admin callers are unchanged.

## Artifacts

The required artifacts are in `fvk/SPEC.md`, `fvk/FINDINGS.md`, `fvk/PROOF_OBLIGATIONS.md`, `fvk/PROOF.md`, and `fvk/ITERATION_GUIDANCE.md`. I also emitted the FVK formal core and adequacy files required by the kit: `fvk/mini-admin-display.k`, `fvk/admin-display-spec.k`, `fvk/INTENT_SPEC.md`, `fvk/PUBLIC_EVIDENCE_LEDGER.md`, `fvk/FORMAL_SPEC_ENGLISH.md`, `fvk/SPEC_AUDIT.md`, and `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.

No tests, Python, or K tooling were run because the task forbids execution.
