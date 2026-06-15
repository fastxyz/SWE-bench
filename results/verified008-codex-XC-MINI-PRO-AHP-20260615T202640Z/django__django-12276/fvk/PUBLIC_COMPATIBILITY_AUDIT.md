# Public Compatibility Audit

Status: constructed for FVK audit, not machine-checked.

## Changed public symbols

`django.forms.FileInput.use_required_attribute(initial)`

- Public shape: new override of an existing documented widget hook.
- Signature: unchanged single `initial` parameter.
- Dispatch impact: plain `FileInput` now suppresses `required` for truthy
  initial values. This is the requested behavior.
- Caller compatibility: `BoundField.build_widget_attrs()` already calls
  `widget.use_required_attribute(self.initial)`, so no caller changes are
  required.

`django.forms.ClearableFileInput.use_required_attribute(initial)`

- Public shape: override removed; behavior inherited from `FileInput`.
- Signature: no public call signature changed because the method remains
  available through inheritance.
- Behavior: unchanged for the documented cases, because the inherited method is
  the same predicate that previously lived on `ClearableFileInput`.

`django.contrib.admin.widgets.AdminFileWidget`

- Public shape: inherits from `ClearableFileInput`.
- Behavior: unchanged for initial-file required-attribute decisions because it
  inherits the same `FileInput` method through `ClearableFileInput`.

## Documentation compatibility

`docs/ref/forms/widgets.txt`

- V1 mismatch: the docs still identified `ClearableFileInput` as the special
  `use_required_attribute(initial)` case.
- V2 resolution: the docs now identify `FileInput`, which includes
  `ClearableFileInput` by inheritance.

No unhandled public override, callsite, or signature incompatibility was found.
