# Baseline Notes

## Root cause

`SelectDateWidget.value_from_datadict()` reads the year, month, and day components directly from submitted form data and attempts to build a `datetime.date(int(y), int(m), int(d))`. The existing code handled `ValueError`, which covers non-numeric values and ordinary out-of-range dates, by returning a pseudo-ISO string for later form validation. It did not handle `OverflowError`, which can be raised when a user submits an integer too large for `datetime.date()`'s C-level conversion. That exception escaped form validation and could crash the request.

## Files changed

`repo/django/forms/widgets.py`

- Updated `SelectDateWidget.value_from_datadict()` to catch `OverflowError` alongside `ValueError`.
- This keeps extremely large date components on the same path as other invalid date components: return a pseudo-ISO value and let the field validation report an invalid date.

## Assumptions and alternatives considered

- I assumed the correct behavior is not to silently coerce or clamp oversized values, because Django already preserves invalid component values so the normal `DateField` validation can reject them.
- I considered pre-validating the numeric range before constructing `datetime.date()`, but catching `OverflowError` is narrower and matches the existing error-handling structure around invalid submitted components.
- I considered returning `None` for overflow values, but rejected that because missing inputs and invalid inputs are intentionally distinguished by the current widget behavior.
