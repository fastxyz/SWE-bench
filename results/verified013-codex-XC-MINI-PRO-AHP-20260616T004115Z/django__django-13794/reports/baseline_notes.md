# Baseline Notes

## Root cause

The `add` template filter in `django/template/defaultfilters.py` first tries to
coerce both operands to integers, then falls back to `value + arg`. Lazy
translation strings are `Promise` proxy objects, not real `str` instances. When
the left operand is a normal string and the right operand is a lazy text proxy,
Python's `str.__add__()` rejects the proxy with `TypeError`, so the filter's
broad exception handler returns an empty string.

## Changed files

- `repo/django/template/defaultfilters.py`: Imported `Promise` and resolved lazy
  text operands to concrete strings at the start of `add()`. This makes lazy
  text behave like normal strings for both the integer coercion step and the
  existing fallback concatenation path.

## Assumptions and alternatives

- I assumed the reported "lazy string" refers to Django's text `Promise` values,
  such as those returned by `gettext_lazy()`.
- I kept the conversion limited to text promises by checking `_delegate_text`.
  Converting every `Promise` to `str` would also fix the reported case, but it
  could unnecessarily change behavior for non-text lazy values that currently
  rely on their proxied type's `+` implementation.
- I rejected changing `django.utils.functional.lazy()` or adding a reverse-add
  method there because the failure is specific to the template filter's operand
  handling, and a global proxy change would have a much wider behavioral surface.
- I did not modify tests, and I did not run tests or project code, per the task
  constraints.
