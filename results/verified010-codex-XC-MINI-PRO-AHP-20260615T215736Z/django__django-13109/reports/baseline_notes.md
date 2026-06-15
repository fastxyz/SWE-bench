# Baseline Notes

## Root cause

`ForeignKey.validate()` checked whether the submitted related value exists by
querying `self.remote_field.model._default_manager`. If the related model's
default manager filters out valid rows, such as archived rows, model validation
treated those rows as missing even when a form intentionally supplied a broader
queryset from `_base_manager`.

## Changed files

`repo/django/db/models/fields/related.py`

- Changed `ForeignKey.validate()` to build its existence query from the related
  model's `_base_manager` instead of `_default_manager`.
- Left the existing database routing, target-field filtering, and
  `limit_choices_to` filtering intact so validation still checks the same
  relation and configured field constraints.

## Assumptions and alternatives

- Assumed the validation step should answer whether the referenced row exists in
  the database, not whether it is included in the related model's default
  application-level filtering. This matches the issue's archived-object example.
- Considered changing form field queryset construction, but rejected it because
  the failing path is model field validation after the form has already supplied
  a deliberate queryset.
- Considered removing or bypassing `limit_choices_to`, but rejected it because
  the issue concerns manager selection only. Existing explicit relation limits
  should continue to participate in validation.
