# Iteration Guidance

Status: constructed, not machine-checked.

## Decision

Keep V1 unchanged.

## Why no additional source edit is justified

- F1 and PO1 identify the operative bug: default-manager existence validation
  rejects a base-visible row. V1 directly changes the existence query to
  `_base_manager`.
- PO2, PO3, and PO4 require preserving routing, explicit `limit_choices_to`, and
  invalid behavior for genuinely missing rows. V1 preserves all three.
- F3 and PO5 found no public compatibility issue: the method signature, caller
  path, exception shape, and form APIs are unchanged.
- The formfield defaults remain `_default_manager` by design. The public issue's
  example explicitly overrides the form field queryset; the failing behavior is
  the later model validation query.

## Residual risk

The proof is constructed over a minimal abstract model, not full Django and not
machine-checked. The emitted K commands should be run in an environment with K
available before using the proof to remove or de-prioritize tests.

## Suggested future checks

- Add or keep a Django integration test for a `ModelForm` whose FK field queryset
  uses `_base_manager` and whose related model default manager filters the chosen
  row.
- Keep tests for `limit_choices_to`, null handling, routers, custom base manager
  names, and normal invalid missing-row behavior.
