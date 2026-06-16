# FVK Iteration Guidance

Status: constructed, not machine-checked.

## Decision

Keep V1 unchanged. The FVK audit found that V1 addresses the shared component-predicate failure
identified by the issue and does not introduce a public compatibility regression.

## Why No Additional Source Edit Is Needed

- F-1 and PO-2 show the old grid construction could exclude encoded boundary cells after a
  floating encode/decode round trip, and V1 fixes that at the shared source of the rejection.
- F-2 and PO-3 show the conservative expansion does not weaken exact filtering: crossing cells
  still call `tree.contains`, and inside cells rely on the existing `Component2D.relate` contract.
- F-3 and PO-6 show V1 is private and source-scoped: no public API, field encoding, query relation,
  or test file changed.
- F-5 rejects the main alternative, a doc-values-only exact contains check, because it would leave
  the shared predicate defect in place.

## Recommended Follow-Up Tests

Do not edit tests in this task. For future maintainers, the public issue suggests adding coverage
for:

- a doc-values polygon query whose bounds are `decode(Integer.MAX_VALUE - 3)` through
  `decode(Integer.MAX_VALUE)` and whose point input is `decode(Integer.MAX_VALUE - 2)`;
- the analogous longitude-boundary case, since V1 intentionally fixes both axes;
- a crossing-cell case that verifies conservative grid expansion still uses exact
  `Component2D.contains`.

## Residual Risks

- The constructed proof is not machine-checked.
- The proof assumes existing `Component2D.relate` implementations are sound with respect to
  decoded point containment.
- Termination is argued by finite monotone `int` movement, not machine-verified.

## Next Iteration Prompt

If more work is requested, focus on machine-checking the compact K model or adding source tests.
Do not replace V1 with a doc-values-only bypass unless new public evidence shows the shared
component predicate should remain approximate.
