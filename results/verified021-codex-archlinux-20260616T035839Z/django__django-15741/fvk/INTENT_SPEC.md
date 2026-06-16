# Intent Spec

Status: constructed for FVK audit, not machine-checked.

## Required Behavior

1. `django.utils.formats.get_format()` accepts a lazy string as its
   `format_type` parameter.
2. A lazy arbitrary date format string, represented by the issue example
   `_("Y-m-d")`, behaves as the concrete string `"Y-m-d"` and is returned as
   the arbitrary-format fallback when no localized module or registered setting
   supplies a value.
3. A lazy string naming a registered format setting or a custom localized
   module attribute behaves as the same concrete string on those lookup paths.
4. The fix belongs in `get_format()`, not only in the `date` template filter,
   because the issue names `get_format()` and notes that other callers may be
   affected.
5. Non-lazy, non-string objects are outside this issue's required domain. The
   audit must not justify broad coercion of arbitrary objects unless separate
   public intent supports it.

## Observed Behavior To Check

Before V1, a lazy string could reach `getattr(module, format_type, None)` as a
non-`str` object and raise `TypeError: getattr(): attribute name must be string`.

V1 converts `Promise` values to `str` inside `get_format()` before the cache key,
module lookup, settings lookup, and arbitrary-format fallback.
