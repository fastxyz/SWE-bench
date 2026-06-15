# FVK Findings

Status: constructed, not machine-checked.

## F1 - Core SameSite preservation is required and V1 satisfies it

Input: `response.delete_cookie("messages", samesite="Lax")`.

Pre-fix observed behavior: deletion header had `Max-Age=0`, expired date, and
path, but no `SameSite`.

Expected behavior: deletion header preserves `SameSite=Lax`.

Audit result: V1 adds `samesite=None` to `delete_cookie()` and passes it to
`set_cookie()`. This satisfies `PO1` and `PO2`.

Classification: fixed code bug.

## F2 - `SameSite=None` deletion requires `Secure` and V1 satisfies it

Input: `response.delete_cookie("messages", samesite="None")`.

Pre-fix observed behavior: no way to emit `SameSite=None`; if added without
`Secure`, modern browsers may ignore the deletion header.

Expected behavior: deletion header has both `SameSite=None` and `Secure`.

Audit result: V1 computes `secure=True` when
`samesite and samesite.lower() == "none"`, while preserving the existing secure
prefix behavior. This satisfies `PO3`.

Classification: fixed code bug.

## F3 - V1 left public docs stale; V2 fixes the documentation

Input: developer reads `docs/ref/request-response.txt` for
`HttpResponse.delete_cookie()`.

V1 observed behavior: source signature accepted `samesite`, but the docs still
showed `delete_cookie(key, path='/', domain=None)`.

Expected behavior: public docs include the new `samesite` argument and explain
that it should match the value used when setting the cookie.

Audit result: V2 updates the docs signature, guidance text, and versionchanged
note. This satisfies `PO6`.

Classification: documentation/API compatibility gap fixed in V2.

## F4 - Built-in messages and sessions call sites must pass SameSite; V1 satisfies them

Input: messages storage or session middleware deletes a cookie configured with
`settings.SESSION_COOKIE_SAMESITE`.

Pre-fix observed behavior: both call sites called `delete_cookie()` without
SameSite, so the core method could not preserve the configured value.

Expected behavior: each call passes the same setting used by its corresponding
`set_cookie()` call.

Audit result: V1 passes `settings.SESSION_COOKIE_SAMESITE` from both call sites.
This satisfies `PO4` and `PO5`.

Classification: fixed code bug.

## F5 - External override compatibility is a residual risk, not a blocker

Input: an out-of-repo `HttpResponse` subclass overrides `delete_cookie()` with
the old signature and is used with Django middleware that passes `samesite`.

Observed from public source: no in-repo overrides exist. The public issue and
hint require adding `samesite` to the public method.

Expected behavior: in-repo public API remains backward compatible for normal
callers; external override authors may need to accept the new optional keyword.

Audit result: no source edit is justified beyond adding the new optional
argument and updating docs. Tracked by `PO6`.

Classification: residual compatibility risk.

## F6 - Verification remains constructed only

Input: the FVK proof package.

Observed behavior: no `kompile`, `kprove`, tests, Python, or Django code were
executed, per task constraints.

Expected behavior: artifacts state exact commands and expected results without
claiming machine-checked proof.

Audit result: proof and test-removal recommendations remain conditional on a
future machine check. Tracked by `PO7`.

Classification: proof honesty constraint.
