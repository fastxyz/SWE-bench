# FVK Spec

Status: constructed, not machine-checked.

## Scope

The audited observable is whether a rendered file input receives the HTML
`required` attribute. The proof models the exact decision composed from:

- `BoundField.build_widget_attrs()`: field-required and form-level gates.
- `Widget.use_required_attribute(initial)`: the widget gate.
- `FileInput.use_required_attribute(initial)`: the V2 file-specific initial
  value rule.
- `ClearableFileInput` and `AdminFileWidget` inheritance.

Template rendering, browser behavior, multipart upload parsing, and full form
validation are outside this mini semantics. The server-side preservation rule in
`FileField.clean()` is used as intent evidence, not re-proven in full.

## Public Intent Ledger

The full ledger is in `PUBLIC_EVIDENCE_LEDGER.md`. Critical entries:

- E1: The issue says `FileInput` should not display `required` when initial
  data exists.
- E3: The issue hint expects `required` when no initial value exists.
- E4: The issue hint expects no `required` for `ContentFile(...)` initial data.
- E5: The issue identifies moving/copying the `ClearableFileInput` method to
  `FileInput` as the intended shape.
- E6: Existing public clearable-file behavior must be preserved.
- E7: `BoundField.build_widget_attrs()` owns field/form-level gating.
- E8: `FileField.clean()` preserves truthy initial file values when no upload is
  submitted.
- E10: Widget docs should describe the class that owns the special case.

## Formal Model

The formal core is:

- `mini-django-fileinput.k`: a small K semantics for the boolean decision.
- `fileinput-required-spec.k`: K reachability claims for the file widget cases,
  inheritance cases, and unaffected generic widget cases.

The model uses a finite initial-state abstraction:

- `initial`: a truthy initial value exists.
- `noInitial`: no truthy initial value exists.

This abstraction is property-complete for this issue because the bug is exactly
about the presence or absence of the rendered `required` attribute as a function
of the initial-value predicate.

## Spec Claims

S1. `FileInput` with `initial`, required field, and enabled form required
attributes returns `false` for `buildRequiredAttr()`.

S2. `FileInput` with `noInitial`, required field, and enabled form required
attributes returns `true`.

S3. `FileInput` returns `false` if either the field-required or form-level gate
is false.

S4. `ClearableFileInput` inherits the same result as `FileInput` for initial and
no-initial cases.

S5. `AdminFileWidget` inherits the same initial-file result through
`ClearableFileInput`.

S6. Generic visible non-file widgets keep the base widget result, and hidden
widgets keep suppressing `required`.

S7. Documentation and public dispatch remain compatible with the new ownership
of the special case.

## Adequacy Result

`SPEC_AUDIT.md` marks all formal-English claims as passing against
`INTENT_SPEC.md`. The only issue surfaced during the FVK audit was a V1
documentation mismatch, recorded as F2 and fixed by updating
`docs/ref/forms/widgets.txt` to name `FileInput`.
