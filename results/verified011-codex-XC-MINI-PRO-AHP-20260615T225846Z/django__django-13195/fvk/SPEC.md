# FVK Specification for django__django-13195

Status: constructed from public intent and source inspection; not
machine-checked.

## Scope

The audited behavior is cookie deletion for `HttpResponseBase.delete_cookie()`
and the Django call sites that delete cookies they previously set with a
SameSite attribute:

- `repo/django/http/response.py`
- `repo/django/contrib/messages/storage/cookie.py`
- `repo/django/contrib/sessions/middleware.py`
- public documentation in `repo/docs/ref/request-response.txt`

No tests, Python, or K tools were executed.

## Intent Specification

I1. `delete_cookie()` must be able to preserve a cookie's SameSite attribute on
the expiring `Set-Cookie` header.

I2. Built-in Django callers that set cookies with
`settings.SESSION_COOKIE_SAMESITE` must pass that same value when deleting those
cookies.

I3. If a deletion header has `SameSite=None`, it must also be `Secure`; otherwise
modern browsers may reject the deletion header.

I4. Existing deletion semantics must remain: value is empty, `Max-Age=0`, the
fixed expired date is used, `path` and `domain` target the cookie, and secure
prefix handling for `__Secure-` and `__Host-` remains intact.

I5. Because `delete_cookie()` is a public method, its documented signature and
usage guidance must match the new argument.

## Public Evidence Ledger

E1. Source: `benchmark/PROBLEM.md`.

Quoted evidence: "HttpResponse.delete_cookie() should preserve cookie's
samesite."

Obligation: I1.

Status: encoded by `PO1` and `PO2`.

E2. Source: `benchmark/PROBLEM.md`.

Quoted evidence: `Set-Cookie: messages=(...); HttpOnly; Path=/; SameSite=Lax`
followed by deletion header `Set-Cookie: messages=""; expires=...; Max-Age=0;
Path=/`.

Obligation: the messages cookie deletion path must preserve the SameSite value
that the set path uses.

Status: encoded by `PO4`.

E3. Source: `benchmark/PROBLEM.md`.

Quoted evidence: "Chrome and Firefox will soon begin ignoring Set-Cookie headers
with Samesite=None that aren't marked 'Secure'."

Obligation: deletion headers carrying `SameSite=None` require `Secure`.

Status: encoded by `PO3`.

E4. Source: public hint in `benchmark/PROBLEM.md`.

Quoted evidence: "we should add the samesite argument to delete_cookie() and
preserve it for deleted cookies".

Obligation: expose `samesite` as an explicit argument to `delete_cookie()` rather
than inferring a global setting for all cookies.

Status: encoded by `PO1`, `PO2`, and `PO6`.

E5. Source: existing source and tests as public compatibility evidence.

Quoted evidence: existing `delete_cookie()` tests assert `expires`,
`max-age`, default path, absent domain, absent secure by default, and secure
handling for `__Secure-` and `__Host-`.

Obligation: keep legacy deletion attributes except where public issue evidence
requires SameSite preservation and `SameSite=None` secure handling.

Status: encoded by `PO1` and `PO3`.

E6. Source: `repo/docs/ref/request-response.txt`.

Quoted evidence before V2: `HttpResponse.delete_cookie(key, path='/',
domain=None)`.

Obligation: public docs must reflect the new public argument.

Status: `F3`; fixed by the V2 documentation edit and encoded by `PO6`.

## Formal Model

The model abstracts the response's cookie jar as a finite map:

`Cookies : Key -> Cookie(value, expires, max_age, path, domain, secure, samesite)`

The relevant functions are:

- `delete_cookie(key, path, domain, samesite)`
- `set_cookie(key, value, max_age, expires, path, domain, secure, httponly,
  samesite)`
- `secure_for_delete(key, samesite) = key.startswith("__Secure-") or
  key.startswith("__Host-") or lower(samesite) == "none"`
- `same_site_attr(samesite) = absent` when `samesite` is falsey, otherwise the
  exact provided value after `set_cookie()` validates it case-insensitively as
  one of `lax`, `strict`, or `none`

This is a reduced mini-Python/K abstraction. It preserves the property under
audit because the observable is exactly the generated cookie attributes.

## K-Style Core Claims

Claim C1: for every valid `SAMESITE`, `delete_cookie(KEY, PATH, DOMAIN,
SAMESITE)` reaches a cookie jar where `KEY` maps to an expired cookie with:

- `value == ""`
- `max_age == 0`
- `expires == "Thu, 01 Jan 1970 00:00:00 GMT"`
- `path == PATH` when `PATH` is not `None`
- `domain == DOMAIN` when `DOMAIN` is not `None`
- `samesite == SAMESITE` when `SAMESITE` is truthy and valid
- `secure == True` exactly when `KEY` has a secure prefix or
  `lower(SAMESITE) == "none"`

Claim C2: if `SAMESITE` is truthy and not one of `lax`, `strict`, or `none`
case-insensitively, the deletion path reaches the same validation failure as
`set_cookie(..., samesite=SAMESITE)`.

Claim C3: `CookieStorage._update_cookie(encoded_data="", response)` calls
`response.delete_cookie(..., samesite=settings.SESSION_COOKIE_SAMESITE)`.

Claim C4: `SessionMiddleware.process_response()` calls
`response.delete_cookie(..., samesite=settings.SESSION_COOKIE_SAMESITE)` when it
deletes an empty existing session.

## Adequacy Audit

The formal claims match the intent:

- C1 covers I1, I3, and I4.
- C2 preserves the existing `set_cookie()` validation domain instead of
  inventing a new `delete_cookie()` validator.
- C3 covers the reported messages-cookie failure.
- C4 covers the analogous built-in session deletion path.
- The V2 documentation edit covers I5.

No claim is derived solely from V1 behavior. Existing behavior is used only for
frame conditions that public tests and docs already expose: expiration date,
`Max-Age=0`, path/domain targeting, and secure prefix handling.

## Public Compatibility Audit

Search result: the only in-repo definition of `delete_cookie()` is
`HttpResponseBase.delete_cookie()`. In-repo call sites are the messages storage,
session middleware, and existing tests/docs.

Adding `samesite=None` at the end of the public signature is backward compatible
for callers using the previous positional or keyword arguments. The audited
in-repo call sites are compatible.

Residual compatibility note: an out-of-repo subclass that overrides
`delete_cookie()` without accepting the new keyword could reject calls that pass
`samesite`. No in-repo evidence exposes such an override, and the public issue
specifically requires adding this argument.
