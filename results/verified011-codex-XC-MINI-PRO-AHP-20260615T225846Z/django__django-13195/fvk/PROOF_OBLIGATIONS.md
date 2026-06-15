# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO1 - Expiring-cookie frame condition

For all cookie names `KEY`, paths `PATH`, domains `DOMAIN`, and SameSite values
`SAMESITE` in the accepted domain, `delete_cookie(KEY, PATH, DOMAIN, SAMESITE)`
must call the cookie-setting transition with:

- empty value
- `max_age = 0`
- `expires = "Thu, 01 Jan 1970 00:00:00 GMT"`
- supplied `PATH`
- supplied `DOMAIN`

Discharge: V1 calls `self.set_cookie(key, max_age=0, path=path, domain=domain,
secure=secure, expires=..., samesite=samesite)`.

Related findings: `F1`.

## PO2 - SameSite preservation

For every truthy valid `SAMESITE` where `lower(SAMESITE)` is `lax`, `strict`, or
`none`, the deletion cookie emitted by `delete_cookie()` must contain
`SameSite=SAMESITE`, preserving the provided value's spelling/case as
`set_cookie()` does.

Discharge: V1 passes `samesite` through to `set_cookie()`, which validates and
serializes the attribute.

Related findings: `F1`.

## PO3 - Secure requirement for browser-accepted deletion

`delete_cookie()` must set `secure=True` when either:

- `KEY` starts with `__Secure-`
- `KEY` starts with `__Host-`
- `SAMESITE` is truthy and `lower(SAMESITE) == "none"`

It must not otherwise change the legacy default of leaving `secure` unset.

Discharge: V1 computes `secure = key.startswith(("__Secure-", "__Host-")) or
(samesite and samesite.lower() == "none")`.

Related findings: `F2`.

## PO4 - Messages call-site preservation

When `CookieStorage._update_cookie()` deletes the messages cookie, it must pass
the same `settings.SESSION_COOKIE_SAMESITE` value used by its set-cookie path.

Discharge: V1 calls `response.delete_cookie(self.cookie_name,
domain=settings.SESSION_COOKIE_DOMAIN,
samesite=settings.SESSION_COOKIE_SAMESITE)`.

Related findings: `F4`.

## PO5 - Sessions call-site preservation

When `SessionMiddleware.process_response()` deletes an empty existing session,
it must pass the same `settings.SESSION_COOKIE_SAMESITE` value used by its
set-cookie path.

Discharge: V1 calls `response.delete_cookie(settings.SESSION_COOKIE_NAME,
path=settings.SESSION_COOKIE_PATH, domain=settings.SESSION_COOKIE_DOMAIN,
samesite=settings.SESSION_COOKIE_SAMESITE)`.

Related findings: `F4`.

## PO6 - Public API and documentation compatibility

Because `delete_cookie()` is documented public API, the source signature and
documentation must both expose the new optional `samesite` argument. Existing
callers using the old argument set must still work.

Discharge: V1 added `samesite=None` at the end of the source signature. V2
updates `docs/ref/request-response.txt` with the new signature, matching-value
guidance, and a versionchanged note. `rg` found no in-repo override of
`delete_cookie()`.

Related findings: `F3`, `F5`.

## PO7 - Proof honesty and non-execution

The FVK proof must not claim tests or K tooling were executed. It must provide
commands that a future machine check would run and label the result constructed,
not machine-checked.

Discharge: `PROOF.md` lists commands and expected outcome without executing
them.

Related findings: `F6`.

## K-Style Claim Sketch

The core reachability claim is:

```k
claim
  <k> delete_cookie(KEY, PATH, DOMAIN, SAMESITE) => .K </k>
  <cookies>
    COOKIES => COOKIES[KEY <- cookie(
      value(""),
      expires("Thu, 01 Jan 1970 00:00:00 GMT"),
      maxAge(0),
      path(PATH),
      domain(DOMAIN),
      secure(secureForDelete(KEY, SAMESITE)),
      sameSiteAttr(SAMESITE)
    )]
  </cookies>
  requires validSameSiteOrAbsent(SAMESITE)
  [all-path]
```

The bundled FVK fast path is stronger for small imperative integer programs than
for this Django object model. The abstraction remains property-complete for this
issue because the exact observable under audit is the cookie attribute map.
