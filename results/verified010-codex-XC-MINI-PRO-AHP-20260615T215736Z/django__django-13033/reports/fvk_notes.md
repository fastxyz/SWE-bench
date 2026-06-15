# FVK Notes

## Decision Summary

V1 stands unchanged. The FVK audit confirms that the one-line change in
`repo/django/db/models/sql/compiler.py` is the minimal source edit required by
the public intent.

## Trace to Findings and Obligations

The decision to keep the V1 predicate change is based on FINDINGS F-001 and
F-002. Both identify the same bug: multi-hop FK attname ordering was wrongly
classified as relation-name ordering, which caused related `Meta.ordering`,
extra self-join generation, and direction inversion. PROOF_OBLIGATIONS PO-001,
PO-002, PO-003, and PO-004 discharge that bug by requiring final-segment
attname comparison and showing how the existing direct branch then orders by
the FK column with the caller's direction.

No additional join-construction change was made because PO-003 shows the
existing `trim_joins()` branch is reached once classification is fixed. This is
also why the self-referential FK shape did not require a separate special case:
the self-join is a symptom of the wrong expansion path, not the root semantic
rule.

No change was made to relation-name ordering because FINDINGS F-003 and PO-005
confirm that `order_by("record__root")` must continue to expand
`OneModel.Meta.ordering`.

No compatibility refactor was made because FINDINGS F-004 and F-005, together
with PO-006 through PO-008, show the V1 edit preserves one-hop FK attnames,
non-relation paths, the `pk` shortcut, the method signature, return shape, and
the recursion guard.

No tests were edited or run. The task forbids test edits and execution, and
`fvk/PROOF.md` labels the proof as constructed, not machine-checked.

## Artifacts Produced

Required benchmark artifacts:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

Additional FVK formal-core artifacts:

- `fvk/mini-django-ordering.k`
- `fvk/django-ordering-spec.k`
