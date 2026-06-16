# Baseline Notes

## Root cause

`MultiValueField` delegates rendering to `MultiWidget`, but the field-level
`required` state was the only state used to add the HTML `required` attribute.
`BoundField.build_widget_attrs()` added `required=True` to the parent
`MultiWidget` whenever the parent field was required. `MultiWidget.get_context()`
then copied that same attribute to every child widget.

That was correct for `require_all_fields=True`, where every subfield is required
as part of the composite value, but it was too coarse for
`require_all_fields=False`. In that mode, individual subfields can be optional,
yet a required parent `MultiValueField` still rendered every subwidget with the
HTML `required` attribute.

## Files changed

`repo/django/forms/fields.py`

- Imported `MultiWidget` so `MultiValueField` can recognize the widget type it
  is designed to work with.
- After initializing subfield validation state, `MultiValueField.__init__()`
  now copies `require_all_fields` to the associated `MultiWidget`.
- For each paired subfield/subwidget, it sets the subwidget's `is_required`
  according to the parent field and the `require_all_fields` policy:
  all subwidgets are required when the parent is required and
  `require_all_fields=True`; only required subfields are required when
  `require_all_fields=False`; no subwidgets are required when the parent field
  itself is optional.

`repo/django/forms/widgets.py`

- Added a default `MultiWidget.require_all_fields = True` to preserve existing
  behavior for ordinary `MultiWidget` usage.
- In `MultiWidget.get_context()`, when `require_all_fields=False` and a
  `required` attribute is being rendered, the attribute is now recalculated per
  subwidget from that subwidget's `is_required` flag and
  `use_required_attribute()` result.
- Child attribute dictionaries are copied for each subwidget before this
  per-widget adjustment so one subwidget's `required` value cannot leak into the
  next one.

## Assumptions and alternatives considered

I assumed the correct fix is for HTML rendering, not validation. The issue
discussion explains that an optional `MultiValueField` with every subfield empty
should remain valid because the composite value can be skipped entirely. I
therefore rejected changing `MultiValueField.clean()` to reject an all-empty
value when `required=False`.

I considered changing `BoundField.build_widget_attrs()` to avoid adding
`required` to partial `MultiValueField` widgets. That alone would remove the
attribute from all child widgets, including required subfields, so it would not
solve the use case.

I also considered making `MultiWidget` always derive child `required` attributes
from child widget state. That would be broader than necessary and could affect
standalone `MultiWidget` rendering. The implemented change keeps the special
per-subwidget behavior limited to `MultiValueField(require_all_fields=False)`.
