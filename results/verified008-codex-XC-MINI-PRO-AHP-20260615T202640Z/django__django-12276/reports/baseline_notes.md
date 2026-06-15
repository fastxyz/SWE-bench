# Baseline Notes

## Root cause

`BoundField.build_widget_attrs()` asks each widget whether it should render the
HTML `required` attribute by calling `widget.use_required_attribute(self.initial)`.
`ClearableFileInput` handled existing initial files by returning `False` when an
initial value was present, because the browser file input itself is blank and the
existing file is kept if the user doesn't upload a replacement.

Plain `FileInput` did not have that override, so it inherited the base widget
behavior and rendered `required` whenever the form field was required. That made
browsers require a new upload even when Django already had an initial file value
that would be preserved by `FileField.clean()`.

## Changed files

`repo/django/forms/widgets.py`

- Added `FileInput.use_required_attribute()` so file inputs suppress the
  `required` attribute when an initial value exists.
- Removed the identical override from `ClearableFileInput`; it now inherits the
  same behavior from `FileInput`, keeping existing clearable-file behavior while
  applying it to all file input widgets.

## Assumptions and alternatives

- Assumed any truthy initial value means Django can preserve an existing file if
  no replacement is uploaded. This matches `FileField.clean()`, which returns the
  initial value when submitted file data is empty.
- Considered changing `BoundField.build_widget_attrs()` or `FileField` instead,
  but rejected that because the issue is specific to file widgets and the
  existing extension point is `Widget.use_required_attribute()`.
- Considered leaving the `ClearableFileInput` override in place, but rejected it
  as redundant once the rule belongs to `FileInput`.
