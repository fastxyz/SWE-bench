# Baseline Notes

## Root cause

`ModelAdminChecks._check_list_display_item()` checked `hasattr(obj.model, item)`
before attempting `obj.model._meta.get_field(item)`. Some model fields expose a
class-level descriptor that raises `AttributeError` when accessed on the model
class, even though the field is present in model metadata. In that case
`hasattr(obj.model, item)` returned `False`, the metadata lookup was skipped, and
admin validation incorrectly reported `admin.E108`.

The same ordering also meant that if a model attribute lookup succeeded but the
metadata lookup failed, the function could return success before checking whether
the resolved object was a `ManyToManyField`.

## Changed files

`repo/django/contrib/admin/checks.py`

- Updated `_check_list_display_item()` so it still accepts callables and
  `ModelAdmin` attributes immediately.
- Changed model item resolution to try `obj.model._meta.get_field(item)` before
  falling back to `getattr(obj.model, item)`.
- Kept `admin.E108` for the case where both metadata lookup and model attribute
  lookup fail.
- Moved the `ManyToManyField` validation after resolution so `admin.E109` is
  applied to fields found through either path.

## Assumptions and alternatives considered

I assumed the intended contract is the one described by the issue: `list_display`
items are valid if they are callables, `ModelAdmin` attributes, model fields, or
model attributes/methods, and `admin.E108` should only be raised after all of
those checks fail.

I considered keeping the existing `hasattr(obj.model, item)` guard and adding a
second `_meta.get_field()` attempt in the `else` branch, but that would preserve
the confusing split between field discovery and attribute discovery and would not
address the missed `ManyToManyField` validation for objects resolved via
`getattr()`.

I did not change `label_for_field()` or other admin lookup helpers because the
reported failure is in startup validation, and this fix targets the validation
path without broadening the behavioral surface.

I did not run tests or project code, per the task constraints.
