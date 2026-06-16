# Public Compatibility Audit

Status: no compatibility blocker found.

## Changed Public Symbols

`django.forms.fields.MultiValueField.__init__`

- Signature changed: no.
- Caller obligations changed: no.
- New behavior: when the resolved widget is a `MultiWidget`, V1 stores the
  existing `require_all_fields` policy on the widget and updates child
  `is_required` flags for rendering.
- Compatibility result: pass. Existing constructor callers still pass the same
  arguments.

`django.forms.widgets.MultiWidget`

- Signature changed: no.
- Subclass override requirements changed: no.
- New class attribute: `require_all_fields = True`, preserving behavior for
  standalone `MultiWidget` usage and subclasses not attached to a
  `MultiValueField`.
- Compatibility result: pass.

`django.forms.widgets.MultiWidget.get_context`

- Signature changed: no.
- Return shape changed: no; it still returns the same widget context with
  `widget['subwidgets']`.
- New behavior: only when `self.require_all_fields` is false and a parent
  `required` attr is present, the child `required` attr is recalculated per
  subwidget.
- Compatibility result: pass.

## Public Subclasses In Source

- `django.forms.widgets.SplitDateTimeWidget`: inherits the class attribute
  default and remains required-all by default.
- `django.contrib.postgres.forms.ranges.RangeWidget`: gets the default class
  attribute when used standalone; when used by `BaseRangeField`, the parent
  `MultiValueField` already sets `require_all_fields=False` and endpoint
  fields are optional.

No public source override of `MultiWidget.get_context()` is forced to accept a
new argument or return a new shape.

