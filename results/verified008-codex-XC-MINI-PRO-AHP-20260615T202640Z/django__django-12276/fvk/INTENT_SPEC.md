# Intent Spec

Status: constructed for FVK audit, not machine-checked.

## Required Behavior

I1. For a required form field rendered with `FileInput`, if an initial file
value exists, the rendered file input must not include the HTML `required`
attribute.

I2. For a required form field rendered with `FileInput`, if no initial file
value exists and `Form.use_required_attribute` is enabled, the rendered file
input should include the HTML `required` attribute.

I3. `ClearableFileInput` must keep its existing behavior: it must not render
`required` when initial data exists, and it must continue to render `required`
for required fields when no initial data exists.

I4. The existing `BoundField.build_widget_attrs()` gates still apply: a widget
can only receive `required` when the field is required, the form allows required
attributes, and the widget's `use_required_attribute(initial)` allows it.

I5. The fix must not change public method signatures or require callers to pass
new arguments. Existing subclasses of `ClearableFileInput`, including admin
file widgets, should inherit compatible behavior.

I6. Public documentation for `Widget.use_required_attribute(initial)` should
name the class that owns the special initial-file behavior.

## Default-Domain Assumptions

- "Initial data exists" means a truthy initial value according to Django's file
  value semantics. This is the same predicate used by `FileField.clean()` when
  it decides whether to preserve an existing value after an empty file upload.
- The proof is about partial correctness of the render-attribute decision. It
  does not prove template rendering, browser behavior, or form submission
  termination.
