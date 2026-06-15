# FVK Iteration Guidance

Verdict: V1 stands unchanged.

## Decisions

1. Keep the V1 source patch.

   Trace: Findings F-001, F-002, and F-003 are resolved or confirmed by proof
   obligations PO-001 through PO-004. The patch refreshes widget attrs after
   dynamic `max_length` assignment and delegates the exact attrs to the concrete
   field's `widget_attrs()` method.

2. Do not add runtime validator rebuilding in this pass.

   Trace: Finding F-004 and PO-005. Validator parity is a plausible broader
   question, but the public issue and task describe a rendered HTML
   `maxlength` regression. Rebuilding validators would change form validation
   and error behavior beyond the established intent.

3. Do not edit tests.

   Trace: the task forbids modifying tests, and Finding F-005 records that no
   proof or test execution was performed. `fvk/PROOF.md` gives test guidance
   only.

## Suggested Next Inputs for a Future Pass

- If maintainers want validator parity, provide a public requirement such as:
  "AuthenticationForm must reject usernames longer than the active user model's
  username field max_length with a field-level max_length error."
- If maintainers only want the HTML regression guarded, add a regression test
  that renders `AuthenticationForm()['username']` and checks the effective
  `maxlength` attribute.

## Implementation Status

No source changes beyond V1 were made during this FVK pass.
