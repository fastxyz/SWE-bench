# FVK Notes

## Decision

V1 stands unchanged. No additional production source edit is justified by the FVK audit.

## Trace to findings and proof obligations

`fvk/FINDINGS.md` F1 identifies the original bug as loss of terminal summary state when `Aggregate.resolve_expression()` wraps a defaulted aggregate in `Coalesce`. `fvk/PROOF_OBLIGATIONS.md` PO1 requires that wrapper to preserve the resolved aggregate's summary flag, and PO2 requires that this make the annotated terminal aggregate plan valid. V1 satisfies both by setting `coalesce.is_summary = c.is_summary`.

F2 addresses the main audit question from the public hint: whether to change V1 to `coalesce.is_summary = True`. PO3 requires non-terminal aggregate annotations with `default` to keep `is_summary=False`, matching the existing `summarize` contract in `BaseExpression.resolve_expression()`. Because V1 preserves `c.is_summary`, it satisfies PO3; the unconditional `True` alternative would over-mark non-terminal annotations in the FVK model.

F3 and PO4 cover compatibility. The fix does not change public signatures, return expression families, constructor behavior, or virtual dispatch shape. The only changed behavior is wrapper metadata used by aggregation planning, so no compatibility repair is needed.

F4 and PO5 cover the honesty gate. The FVK `.k` claims and proof are constructed only, not machine-checked, because the task forbids running K tooling, Python, tests, or project code. This limits proof confidence and test-removal recommendations, but it does not create a source-level change request.

## Artifacts produced

The requested artifacts are complete:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

The FVK formal core and adequacy artifacts are also present:

- `fvk/mini-django-aggregate.k`
- `fvk/aggregate-default-spec.k`
- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`

No test files were modified and no commands that execute project code, tests, Python, or K tooling were run.
