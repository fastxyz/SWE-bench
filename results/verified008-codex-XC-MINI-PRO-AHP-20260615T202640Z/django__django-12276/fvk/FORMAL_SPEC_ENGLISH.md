# Formal Spec in English

Status: constructed for FVK audit, not machine-checked.

The K model formalizes a finite boolean decision:

- `initial` means a truthy initial value exists.
- `noInitial` means no truthy initial value exists.
- `buildRequiredAttr(widget, initialState, fieldRequired, formUseRequired)`
  returns whether `BoundField.build_widget_attrs()` should include the rendered
  `required` attribute.

## Claim Paraphrases

C1. For `FileInput`, `buildRequiredAttr(FileInput, initial, true, true)` is
`false`.

C2. For `FileInput`, `buildRequiredAttr(FileInput, noInitial, true, true)` is
`true`.

C3. For `FileInput`, if either the field is not required or the form-level
required-attribute flag is disabled, `buildRequiredAttr()` is `false`.

C4. `ClearableFileInput` inherits the same `use_required_attribute(initial)`
decision as `FileInput`; therefore it is false for `initial` and true for
`noInitial` when the field and form gates are true.

C5. `AdminFileWidget`, as a subclass through `ClearableFileInput`, inherits the
same initial-file decision.

C6. A generic visible non-file widget remains unaffected in the model: with the
field and form gates true, its required decision does not depend on initial
data.

C7. A hidden widget remains unable to render `required`, preserving the base
widget hidden gate.

C8. The source and docs remain API-compatible: `use_required_attribute(initial)`
keeps the same single-argument public method signature, and the docs identify
`FileInput` as the special case.
