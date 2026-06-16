# Baseline Notes

## Root Cause

`django.utils.formats.get_format()` accepted `format_type` values that were
documented and expected to behave like strings, including arbitrary date format
strings that are not registered settings names. After the format-settings guard
was tightened, the function still used `format_type` directly as a cache key and
as the attribute name in `getattr(module, format_type, None)`.

Django lazy translation objects are `Promise` instances, not concrete `str`
instances, until they are evaluated. Passing a lazy string such as
`gettext_lazy("Y-m-d")` through the `date` template filter therefore allowed a
non-`str` object to reach `getattr()`, raising `TypeError: getattr(): attribute
name must be string`.

## Changed Files

`repo/django/utils/formats.py`

Converted `Promise` values passed as `format_type` to `str` at the start of
`get_format()` before cache lookup, localized format-module lookup, settings
lookup, or arbitrary-format fallback. This keeps the fix in the shared helper so
direct callers and template filters use the same behavior.

## Assumptions

The issue is about lazy string values used as format names or arbitrary format
strings. `get_format()` already documents `format_type` as a string name, so the
change only evaluates Django `Promise` instances instead of coercing every
possible non-string input.

## Alternatives Considered

Changing only the `date` template filter was rejected because the same failure
can occur for any caller that passes a lazy string to `get_format()`, including
other helpers using localized formats.

Coercing all `format_type` values with `str()` was rejected because it would
change behavior for invalid non-string inputs such as `None` or integers. The
targeted `Promise` handling fixes lazy strings without broadening unrelated
coercion behavior.
