# FVK Iteration Guidance

Status: constructed, not machine-checked.

## Decision

V1's production code stands. The FVK audit found one improvement outside the
runtime code: V1 changed a public method signature but left the request/response
documentation stale. V2 updates the docs.

## Applied Change

Update `repo/docs/ref/request-response.txt` so
`HttpResponse.delete_cookie()` documents `samesite=None`, explains that it
should match the value used with `set_cookie()`, and records the 3.2 version
change.

Justification: `F3` and `PO6`.

## Rejected Alternatives

Do not add session-specific defaults inside `delete_cookie()`.

Reason: the public hint asks for an explicit `samesite` argument. Applying
`SESSION_COOKIE_SAMESITE` inside the core method would incorrectly impose
session settings on unrelated cookies. This is covered by `PO2`, `PO4`, and
`PO5`.

Do not add general `secure` or `httponly` arguments in this iteration.

Reason: the issue's security requirement is specifically `SameSite=None` needing
`Secure`, plus existing secure-prefix behavior. Cookie deletion targets name,
path, and domain; preserving `httponly` is not required to delete the cookie.
This is covered by `PO1` and `PO3`.

Do not attempt fallback dispatch for hypothetical external overrides of
`delete_cookie()`.

Reason: no in-repo overrides exist, and the public issue requires adding the new
argument. A fallback would add complexity without public-source evidence of a
failing in-domain case. This residual risk is recorded as `F5`.

## Next Iteration If Execution Becomes Available

Run the Django tests relevant to response cookies, messages cookies, and session
cookies. In this benchmark turn, execution is forbidden.

If K artifacts are extracted from the claim sketches, run:

```sh
kompile fvk/mini-cookie-response.k --backend haskell
kast --backend haskell fvk/cookie-delete-spec.k
kprove fvk/cookie-delete-spec.k
```

Treat any non-`#Top` result as a proof-derived finding and revisit
`PROOF_OBLIGATIONS.md`.
