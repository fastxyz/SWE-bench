# Public Compatibility Audit

Status: constructed from source inspection; not machine-checked.

## Changed public symbol

`django.forms.widgets.CheckboxInput.get_context(self, name, value, attrs)`

V1 keeps the same method name, parameters, return path, and exception behavior. The only source-level change is that non-`None` `attrs` is copied before adding a generated `checked` key.

## Callers and overrides

Public callers continue to pass `attrs` in the same position. The base `Widget.render()` path still calls `self.get_context(name, value, attrs)`. `Input.get_context()` and `Widget.get_context()` signatures are unchanged. `SplitArrayWidget.get_context()` still calls the child widget as `self.widget.get_context(name_i, widget_value, final_attrs)`.

No override must be updated because no new parameter or return shape was introduced. No producer/consumer storage format changes.

## Compatibility verdict

Pass. V1 is backward-compatible at the public API level. A caller that intentionally supplied `attrs={'checked': True}` still receives checked output; a caller that inspects the original attrs after rendering no longer sees a generated mutation, which is the intended bug fix rather than a compatibility break.
