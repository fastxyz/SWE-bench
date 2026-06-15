# Iteration Guidance

Status: constructed, not machine-checked.

## Decision

V1's source-code fix stands: `FileInput.use_required_attribute(initial)` is the
right ownership point for the initial-file `required` decision, and removing the
duplicate `ClearableFileInput` override preserves behavior through inheritance.

V2 adds one documentation consistency edit:

- `docs/ref/forms/widgets.txt` now lists `FileInput` as the special
  `use_required_attribute(initial)` case.

## Why No Further Code Change Is Needed

- F1 is resolved by the existing V1 code and PO-1 through PO-6.
- F3 confirms the no-initial case remains correct via PO-2.
- F4 confirms `ClearableFileInput` and `AdminFileWidget` inheritance via PO-5
  and PO-7.
- No compatibility audit entry found a changed signature or unhandled public
  override.

## Follow-Up Work Outside This Restricted Session

- Machine-check the K artifacts with the emitted commands.
- Add or keep tests for the two `FileInput` rendering cases from the issue.
- Keep any test deletion recommendation conditional on `kprove` returning
  `#Top`.
