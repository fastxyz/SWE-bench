# Iteration Guidance

Status: V1 stands unchanged.

## Decision

Do not edit production source for V2. The FVK audit found that V1 satisfies the
intent-derived obligations in `SPEC.md`:

- F1 / PO4 / PO10 show disabled callable initials now flow through
  `BoundField.initial`.
- F2 / PO5 show `FileField` initial cleaning now uses `bf.initial`.
- F3 / PO7 / PO8 / PO9 show `changed_data` is now a bound-field aggregation
  with per-field logic on `BoundField`.
- F4 shows hidden-initial semantics are preserved.
- F5 / PO11 identify only a residual private-API compatibility note, not a
  code bug requiring a fallback.

## Recommended Future Checks

1. In an environment where execution is allowed, run Django's relevant forms
   tests and add or inspect coverage for the disabled callable `DateTimeField`
   case described in the public issue.
2. If K tooling is available, replace the abstract K functions in
   `mini-django-forms.k` with a more concrete mini-Python object semantics and
   run the commands recorded in `PROOF.md`.
3. Keep tests that cover integration behavior, custom fields, `FileField`,
   hidden initial values, disabled fields, and callable initial values until
   machine-checked proof artifacts exist.

## Repair Guidance If A Future Failure Appears

- If a failure involves a custom `BoundField` subclass, prefer adding
  `_has_changed()` to that subclass or documenting the private bound-field
  compatibility expectation. Reintroducing duplicated `BaseForm.changed_data`
  logic should be a last resort because it conflicts with I2 and I4.
- If a failure involves cleaned data differing from rendered initial values,
  localize the path by checking whether `_clean_fields()` receives `bf.initial`
  or a separately evaluated initial value.
- If a failure involves `show_hidden_initial`, compare the hidden-widget
  extraction and `to_python()` exception path against PO8 before changing code.
