# FVK Findings

Status: constructed, not machine-checked.

## F1: Plain FileInput rendered `required` despite initial data

- Classification: code bug, resolved by V1 and confirmed by V2.
- Evidence: E1, E2, E4, E5.
- Input: required `FileField(widget=FileInput)` with truthy initial file data,
  form-level `use_required_attribute=True`, and no submitted replacement file.
- Observed before V1: `BoundField.build_widget_attrs()` called the inherited
  base widget method, so the rendered file input received `required`.
- Expected: no rendered `required` attribute, because the existing initial file
  value is preserved when the user submits no replacement.
- Resolution: `FileInput.use_required_attribute(initial)` now returns
  `super().use_required_attribute(initial) and not initial`.
- Proof obligations: PO-1, PO-3, PO-4, PO-6.

## F2: V1 left the public widget docs naming only ClearableFileInput

- Classification: documentation/API consistency issue, resolved by V2.
- Evidence: E10.
- Input: public docs for `Widget.use_required_attribute(initial)` after moving
  the special case to `FileInput`.
- Observed in V1: the docs still said the special case was
  `ClearableFileInput`, even though the code now owned it on `FileInput`.
- Expected: docs should identify `FileInput`, which also covers
  `ClearableFileInput` by inheritance.
- Resolution: `docs/ref/forms/widgets.txt` now names `FileInput`.
- Proof obligations: PO-8.

## F3: No regression for required FileInput without initial data

- Classification: confirmed behavior.
- Evidence: E3.
- Input: required `FileField(widget=FileInput)` with no initial value and
  form-level `use_required_attribute=True`.
- Expected and V2 result: `required` is still rendered.
- Proof obligations: PO-2.

## F4: No regression for ClearableFileInput or AdminFileWidget inheritance

- Classification: confirmed behavior.
- Evidence: E5, E6 and public subclass inspection.
- Input: `ClearableFileInput` or `AdminFileWidget` with initial data.
- Expected and V2 result: no `required` attribute is rendered; with no initial
  data and required/form gates true, `ClearableFileInput` still allows
  `required`.
- Proof obligations: PO-5, PO-7.

## F5: Machine-checking was not run

- Classification: proof caveat, not a source bug.
- Evidence: task restriction and FVK honesty gate.
- Input: the constructed K files and claims.
- Observed: no `kompile`, `kast`, or `kprove` command was executed.
- Expected: artifacts include exact commands and remain labeled
  "constructed, not machine-checked."
- Resolution: no source change. Keep any test-removal recommendation
  conditional on later machine-checking.
- Proof obligations: all obligations are constructed only.

## Unresolved Findings

None.
