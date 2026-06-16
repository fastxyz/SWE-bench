# FVK Notes

## Decision summary

V1 stands unchanged. No additional source edits were made after the FVK audit.

## Decisions traced to FVK artifacts

1. Kept `repo/django/forms/fields.py` at the V1 implementation:
   `json.dumps(value, ensure_ascii=False, cls=self.encoder)`.

   Trace: `fvk/FINDINGS.md` F-001 identifies the pre-V1 bug as default ASCII escaping in display serialization. `fvk/PROOF_OBLIGATIONS.md` PO-002 requires non-ASCII Unicode display preservation and is discharged by the V1 call shape.

2. Kept the `InvalidJSONInput` branch unchanged.

   Trace: `fvk/FINDINGS.md` F-002 says invalid JSON redisplay must remain unchanged. `fvk/PROOF_OBLIGATIONS.md` PO-001 proves the first branch returns invalid input without calling JSON serialization.

3. Did not change database JSON serialization.

   Trace: `fvk/FINDINGS.md` F-003 records the database/storage path as a frame condition. `fvk/PROOF_OBLIGATIONS.md` PO-005 ties that decision to the issue text saying the fix is admin/display-only and to the unchanged `repo/django/db/models/fields/json.py` path.

4. Did not alter custom encoder handling.

   Trace: `fvk/FINDINGS.md` F-004 records custom encoder dispatch as a compatibility requirement. `fvk/PROOF_OBLIGATIONS.md` PO-004 confirms the symbolic encoder is still passed through as `cls=self.encoder`.

5. Did not change form widget rendering or mark JSON display strings safe.

   Trace: `fvk/PROOF_OBLIGATIONS.md` PO-006 records widget/template rendering as a frame condition. Since V1 only changes the string produced by `prepare_value()`, the existing `BoundField`/`Widget`/`Textarea` path remains intact.

6. Did not run tests, Python snippets, `kompile`, `kast`, or `kprove`.

   Trace: `fvk/FINDINGS.md` F-005 records this as a proof execution boundary, not a code bug. `fvk/PROOF_OBLIGATIONS.md` lists the future machine-check commands without executing them.

## Artifacts produced

Required FVK artifacts:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

Additional formal-core artifacts required by the FVK method:

- `fvk/mini-json-form.k`
- `fvk/jsonfield-prepare-value-spec.k`
- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`

## Assumptions

The FVK spec treats Python's `json.dumps(..., ensure_ascii=False, cls=encoder)` as the intended display serializer for non-invalid JSONField form values. It abstracts the full Python JSON library in the mini K semantics but preserves the audited property axis: `ensure_ascii=True` and `ensure_ascii=False` produce different observable states for the public non-ASCII example.

The proof is constructed, not machine-checked. This limits proof confidence and test-redundancy claims, but it does not alter the source decision because the source-level obligations that matter for this issue are discharged by intent and static code inspection.
