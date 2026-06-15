# Iteration Guidance

Status: constructed, not machine-checked.

## Decision

V1 stands unchanged. The FVK audit found that the V1 edit discharges PO-1
through PO-5, which cover the public issue obligations.

## No Source Changes Required

No additional source edit is justified by `fvk/FINDINGS.md` for
django__django-12262:

- F-1 and F-2 are the reported failures and are fixed by V1.
- F-3 confirms the key existing error behaviors remain intact.
- F-4 confirms the shared helper reaches `simple_tag()` and `inclusion_tag()`.
- F-5 is an adjacent, unclaimed duplicate-diagnostic question and should not be
  folded into this targeted repair without a separate public obligation.

## Suggested Future Tests

Do not edit tests in this task. If adding public tests in a normal development
setting, add:

- `simple_tag` with `def tag(*, greeting='hello')` and
  `{% tag greeting='hi' %}`.
- `inclusion_tag` with the same keyword-only default shape.
- `simple_tag` duplicate keyword-only required parameter:
  `{% tag greeting='hi' greeting='hello' %}`.
- `inclusion_tag` duplicate keyword-only required parameter.
- Regression checks that unknown keywords and missing required keyword-only
  parameters keep their existing errors.

## Suggested Future Clarification

Ask separately whether Django should raise a compile-time `TemplateSyntaxError`
for a positional argument plus a later keyword using the same parameter name.
That is related to Python call semantics but is not required to close this
issue's repeated-keyword-token defect.
