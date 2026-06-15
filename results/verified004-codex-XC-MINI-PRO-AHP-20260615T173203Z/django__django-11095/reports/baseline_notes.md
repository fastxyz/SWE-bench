# Baseline Notes

## Root cause

`ModelAdmin.get_inline_instances()` built inline admin instances by iterating
directly over `self.inlines`. Because there was no hook that returned the
inline classes before instantiation and permission filtering, callers who only
wanted to vary the inline class list by request or object had to override
`get_inline_instances()` and copy its instance-construction and permission
logic.

## Files changed

`repo/django/contrib/admin/options.py`

- Added `ModelAdmin.get_inlines(request, obj=None)`, whose default
  implementation returns `self.inlines`.
- Updated `ModelAdmin.get_inline_instances()` to iterate over
  `self.get_inlines(request, obj)` so subclasses can customize the inline
  class list while preserving Django's existing inline instantiation and
  permission behavior.
- Updated `BaseModelAdmin.to_field_allowed()` to consult
  `admin.get_inlines(request)` when gathering registered inline models. This
  keeps related-object validation consistent with inline classes supplied by
  the new request-aware hook.

## Assumptions and alternatives

- I assumed the requested API should mirror nearby `ModelAdmin` hooks such as
  `get_fields()` and `get_readonly_fields()`: a small method returning the
  configured value by default, with existing downstream behavior left intact.
- I did not move inline permission checks into the new hook. The issue asks to
  customize inline classes, not inline instances, and preserving
  `get_inline_instances()` behavior avoids changing existing permission
  semantics.
- I left system checks based on the static `inlines` attribute. Admin checks run
  without a request or object, so validating arbitrary dynamic values from
  `get_inlines()` would be unreliable. This matches the existing pattern for
  other dynamic `ModelAdmin` hooks.
- I did not edit tests or run the test suite because the task instructions
  explicitly forbid modifying tests and running tests or project code.
