# FVK Notes

## Source Decision

No additional source edit was made after V1.

This decision traces to `fvk/FINDINGS.md`:

- F-001 confirms that V1 fixes the public singleton tuple defect.
- F-002 confirms the frame conditions for empty tuples, multi-element tuples, lists, and nested rendering.
- F-003 confirms there is no compatibility issue from the helper change.
- F-004 is explicitly out of this issue's domain and does not justify a code change.

It also traces to `fvk/PROOF_OBLIGATIONS.md`:

- PO-2 is discharged by the V1 `len(arg) == 1` branch.
- PO-5 is discharged because `_EvaluatorPrinter.doprint` inserts the corrected string directly into `return {str_expr}`.
- PO-3 and PO-4 are discharged by leaving the existing shared list/tuple recursive join path unchanged for all non-singleton tuple cases.
- PO-6 is discharged because no signature or caller protocol changed.

## Artifact Decisions

I wrote the five requested FVK artifacts:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

I also wrote the supporting FVK core required by the methodology:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
- `fvk/mini-python.k`
- `fvk/lambdify-recursive-to-string-spec.k`

The extra artifacts are necessary because the FVK documentation marks a Markdown-only run invalid and requires `.k` claims plus adequacy and compatibility audits.

## Execution Constraint

No tests, Python snippets, or K commands were run. The proof is recorded as constructed, not machine-checked, as required by the task constraints and PO-7.

