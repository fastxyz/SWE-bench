# Baseline Notes

## Root cause

`HttpResponseBase.delete_cookie()` expired cookies by calling `set_cookie()` with
`max_age=0`, `expires`, `path`, `domain`, and the existing secure-prefix
handling, but it had no `samesite` argument. Callers that created cookies with a
`SameSite` attribute, such as the messages and sessions code, therefore emitted
delete headers without `SameSite`. For cookies configured as `SameSite=None`,
that missing preservation is especially problematic because modern browsers
require `Secure` on `SameSite=None` cookies and may ignore the deletion header.

## Changed files

`repo/django/http/response.py`

- Added an optional `samesite` argument to `HttpResponseBase.delete_cookie()`.
- Passed the value through to `set_cookie()` so the existing validation and
  header serialization are reused.
- Extended the existing `secure` calculation so deletion headers are marked
  secure for `SameSite=None`, matching browser requirements while keeping the
  current `__Secure-` and `__Host-` behavior.

`repo/django/contrib/messages/storage/cookie.py`

- Passed `settings.SESSION_COOKIE_SAMESITE` when deleting the messages cookie,
  matching the value used when setting that cookie.

`repo/django/contrib/sessions/middleware.py`

- Passed `settings.SESSION_COOKIE_SAMESITE` when deleting the session cookie,
  matching the value used when setting that cookie.

## Assumptions and alternatives

- I assumed the intended API change is to make SameSite preservation explicit on
  `delete_cookie()` rather than trying to infer cookie attributes from the
  request, because the response object does not have reliable access to the
  original `Set-Cookie` attributes.
- I kept the change limited to SameSite preservation and the required
  `SameSite=None` secure behavior. I did not add `secure` or `httponly`
  parameters to `delete_cookie()` because the public issue and hint specifically
  identify `samesite`, and cookie deletion only needs name, path, and domain to
  target the existing cookie.
- I updated the built-in messages and sessions callers because they already use
  `SESSION_COOKIE_SAMESITE` when setting their cookies. Without these call-site
  changes, adding the new argument to `delete_cookie()` would not fix the
  reported messages-cookie behavior.
- I did not modify tests or run the test suite because the task instructions
  prohibit changing test files and executing code in this workspace.
