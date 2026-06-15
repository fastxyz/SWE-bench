# Baseline Notes

## Root Cause

`SecurityMiddleware` only adds the `Referrer-Policy` header when
`settings.SECURE_REFERRER_POLICY` is truthy. The global default was `None`, so
projects using the middleware without explicitly configuring the setting did
not emit a `Referrer-Policy` header and could leak full referrer URLs to
third-party sites.

## Changed Files

`repo/django/conf/global_settings.py`

Changed `SECURE_REFERRER_POLICY` from `None` to `'same-origin'`, making
SecurityMiddleware emit `Referrer-Policy: same-origin` by default while keeping
`None` available as an explicit opt-out.

`repo/docs/ref/settings.txt`

Updated the documented default, clarified that setting the value to `None`
disables the header, and added a Django 3.1 versionchanged note for the default
change.

`repo/docs/releases/3.1.txt`

Added the backwards-incompatible-change note requested by the issue discussion,
including the opt-out for applications that need the previous behavior.

## Assumptions and Alternatives

I assumed the issue asks for the setting default to change, not for
`SecurityMiddleware` to hard-code a header independently of the setting. Keeping
the behavior in the setting preserves existing custom values, response-level
overrides, and the existing `None` opt-out.

I considered changing the middleware to special-case an unset setting, but that
would duplicate responsibility already handled by `global_settings.py`. I also
considered changing the security check warning text for `None`, but the check
still applies to the effective disabled state and changing it is not required
for the requested default behavior.
