# PUBLIC COMPATIBILITY AUDIT

Status: constructed from public source reads. No tests, Python, or tooling were
run.

## Changed Symbol

`AdminSite.catch_all_view(self, request, url)`

- Signature: unchanged.
- Decorators: unchanged (`@no_append_slash` remains).
- Registration: unchanged. `get_urls()` still registers
  `re_path(r"(?P<url>.*)$", wrap(self.catch_all_view))` when
  `final_catch_all_view` is true.
- Return/error shape: unchanged at the branch level. The redirect branch still
  returns `HttpResponsePermanentRedirect`; the fallback still raises `Http404`.

## Public Callers and Dispatch

Observed public source references:

- `django/contrib/admin/sites.py`: `get_urls()` wraps `self.catch_all_view`.
- No other source reference under `repo/django` calls `catch_all_view`
  directly.

The edit does not add arguments to virtual dispatch and does not require
subclasses overriding `catch_all_view()` to accept a new signature.

## Related Protocol

`should_append_slash` is still read through
`getattr(match.func, "should_append_slash", True)`. The fix does not change that
protocol and does not change `django.views.decorators.common.no_append_slash`.

## Verdict

No public compatibility issue found.
