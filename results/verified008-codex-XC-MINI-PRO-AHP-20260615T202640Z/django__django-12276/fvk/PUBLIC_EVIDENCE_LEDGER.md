# Public Evidence Ledger

Status: constructed for FVK audit, not machine-checked.

| ID | Source | Quoted evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "FileInput shouldn't display required attribute when initial data exists." | `FileInput` must suppress `required` when initial data is present. | Encoded by PO-1 and K claims `FILEINPUT-INITIAL-*`. |
| E2 | prompt | "`required` is not output ... when a file is already set (e.g. already saved on a model instance that is being edited)." | Existing file values should satisfy the field without browser-forced re-upload. | Encoded by PO-1 and PO-6. |
| E3 | prompt hint | Expected no-initial rendering: `<input type=\"file\" name=\"file\" required id=\"id_file\">`. | Required file fields with no initial value keep `required`. | Encoded by PO-2. |
| E4 | prompt hint | Expected initial rendering with `ContentFile(...)`: `<input type=\"file\" name=\"file\" id=\"id_file\">`. | Truthy initial file values remove `required` for plain `FileInput`. | Encoded by PO-1. |
| E5 | prompt hint | "If the use_required_attribute() method is copied from ClearableFileInput to FileInput this passes." | The rule belongs on `FileInput`, with `ClearableFileInput` inheriting or preserving equivalent behavior. | Encoded by PO-1 and PO-5. |
| E6 | public test/comment | Clearable-file test says false when "initial data exists" because the user can keep the existing initial value. | Preserve `ClearableFileInput` behavior. | Encoded by PO-5. |
| E7 | source | `BoundField.build_widget_attrs()` adds `required` only if widget, field, and form gates all allow it. | The fixed method must compose with existing field/form gates. | Encoded by PO-3 and PO-4. |
| E8 | source | `FileField.clean()` returns `initial` when submitted file data is empty and `initial` is truthy. | Suppressing browser `required` with truthy initial is semantically aligned with server-side preservation. | Encoded by PO-6. |
| E9 | source/docs | `Widget.use_required_attribute(initial)` is the documented extension point. | Fix should use the widget hook, not special-case `BoundField` or `FileField`. | Encoded by PO-7. |
| E10 | source/docs | The docs list special cases for `use_required_attribute(initial)`. | Documentation should describe `FileInput` after the behavior moved there. | Encoded by PO-8. |
