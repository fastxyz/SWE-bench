# PUBLIC_COMPATIBILITY_AUDIT

Status: source and docs inspected; no code or tests run.

## Changed public symbol

`django.contrib.auth.backends.ModelBackend.authenticate`

- Signature before V1:
  `authenticate(self, request, username=None, password=None, **kwargs)`
- Signature after V1:
  unchanged.
- Return shape:
  unchanged: authenticated user object or `None`.
- New dispatch shape:
  none. V1 does not add arguments to virtual calls and does not alter
  `user_can_authenticate(user)`.

## Public callers

- `django.contrib.auth.authenticate()` calls backend `authenticate()` methods
  with `request` and arbitrary credentials after `inspect.getcallargs()`.
  Because `ModelBackend.authenticate()` still accepts the same arguments and
  returns `None` for declined credentials, dispatcher compatibility is
  preserved.

## Subclasses and overrides

- `AllowAllUsersModelBackend` inherits `authenticate()` and overrides only
  `user_can_authenticate()`. V1 preserves that call on complete credentials.
- Repository test helper subclasses of `ModelBackend` found by source search
  inherit the method without requiring a signature change.
- `RemoteUserBackend` subclasses `ModelBackend` but defines its own
  `authenticate(request, remote_user)`, so the V1 method-body guard does not
  affect remote-user dispatch.

## Verdict

No public compatibility issue was found.

