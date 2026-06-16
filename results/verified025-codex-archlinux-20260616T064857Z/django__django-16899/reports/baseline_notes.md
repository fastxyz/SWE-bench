# Baseline Notes

## Root cause

The `readonly_fields` admin check already receives both the indexed option label
(for example, `readonly_fields[0]`) and the configured value being checked.
However, the `admin.E035` error in
`django/contrib/admin/checks.py` only interpolated the indexed label, the
`ModelAdmin` class name, and the model label. It omitted the invalid
`readonly_fields` value, unlike nearby admin checks such as `list_display`,
`list_display_links`, and `list_editable`, which include the referenced value in
their error messages.

## Changed files

`repo/django/contrib/admin/checks.py`

Updated the `admin.E035` message in `_check_readonly_fields_item()` so an
invalid `readonly_fields` entry is reported as the value that
`readonly_fields[n]` refers to. This keeps the existing validation behavior and
error id unchanged while adding the missing field name to the message.

## Assumptions and rejected alternatives

I assumed the desired behavior is a message shaped like Django's neighboring
checks:

`The value of 'readonly_fields[0]' refers to '<field name>', which is not a callable, an attribute of '<ModelAdmin>', or an attribute of '<model>'.`

I considered using the shared `refer_to_missing_field()` helper, but rejected it
because `readonly_fields` can also refer to callables and attributes on the
`ModelAdmin` or model class, so the existing `admin.E035` wording is more
accurate than the helper's field-only wording.

I did not change any tests or run the test suite, as required by the benchmark
instructions.
