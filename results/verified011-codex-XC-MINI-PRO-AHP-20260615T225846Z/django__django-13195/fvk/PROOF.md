# FVK Proof

Status: constructed, not machine-checked. No tests, Python, Django code, or K
tooling were executed.

## Claim Proved in the Model

For all valid inputs in the modeled domain, `delete_cookie(key, path, domain,
samesite)` emits an expired cookie for `key` that preserves the supplied
SameSite value, preserves existing expiration/path/domain behavior, and sets
`Secure` when required by secure prefixes or `SameSite=None`.

The messages and sessions deletion paths satisfy the core claim because each
passes `settings.SESSION_COOKIE_SAMESITE`, the same value used when setting
those cookies.

## Symbolic Proof Sketch

1. Start from `delete_cookie(KEY, PATH, DOMAIN, SAMESITE)`.

2. Evaluate the `secure` expression.

   The expression rewrites to `True` exactly when `KEY` starts with
   `__Secure-`, `KEY` starts with `__Host-`, or `SAMESITE` is truthy and
   `lower(SAMESITE) == "none"`. This discharges `PO3`.

3. Symbolically step into `set_cookie()` with:

   `value=""`, `max_age=0`, `path=PATH`, `domain=DOMAIN`, computed `secure`,
   fixed expired `expires`, and `samesite=SAMESITE`.

   This discharges the call-shape part of `PO1`.

4. Symbolically execute the relevant `set_cookie()` branches.

   `self.cookies[KEY] = ""` sets the target cookie value. Since `expires` is
   non-`None` and not a datetime in this call, `expires` is assigned to the
   fixed epoch string. Since `max_age` is not `None`, `max-age` is assigned `0`;
   because `expires` is already truthy, the `http_date(time.time() + max_age)`
   fallback does not replace it. Non-`None` path/domain are assigned. Truthy
   `secure` assigns the secure attribute. Truthy valid `samesite` is validated
   and assigned unchanged.

   These steps discharge `PO1` and `PO2`.

5. Invalid SameSite values follow the existing `set_cookie()` validation path.

   The proof does not introduce a new validator. `delete_cookie()` reaches
   `set_cookie(..., samesite=SAMESITE)`, and `set_cookie()` raises the same
   `ValueError` for values whose lowercase form is not `lax`, `none`, or
   `strict`.

6. Compose call-site proofs.

   In messages storage, the delete branch passes
   `settings.SESSION_COOKIE_SAMESITE`; by transitivity with the core claim, the
   messages deletion header preserves SameSite. This discharges `PO4`.

   In session middleware, the empty-existing-session delete branch passes
   `settings.SESSION_COOKIE_SAMESITE`; by transitivity with the core claim, the
   session deletion header preserves SameSite. This discharges `PO5`.

7. Public API proof obligation.

   The source signature adds the optional argument at the end, so old callers
   remain valid. The V2 documentation edit makes the public docs match the
   source and records the version change. In-repo search found no subclass
   override of `delete_cookie()`. This discharges `PO6` for the available public
   source.

## Adequacy Result

The proof obligations cover the full public intent from the issue:

- preserving SameSite on deleted cookies;
- doing so for the reported messages path;
- preserving the analogous session path;
- setting `Secure` for `SameSite=None`;
- keeping existing deletion behavior and secure-prefix behavior;
- documenting the public API change.

No proof obligation relies on hidden tests, original upstream patches, or
execution results.

## Commands for Future Machine Check

These commands are recorded for a future full K artifact extraction. They were
not run in this workspace.

```sh
kompile fvk/mini-cookie-response.k --backend haskell
kast --backend haskell fvk/cookie-delete-spec.k
kprove fvk/cookie-delete-spec.k
```

Expected result after extracting the model in `SPEC.md` and
`PROOF_OBLIGATIONS.md` to `.k` files: `#Top`.

## Test Guidance

No tests were modified. No tests should be removed based on this constructed
proof unless the K artifacts are later machine-checked and `kprove` returns
`#Top`.

Recommended tests to keep or add in a normal development environment:

- `delete_cookie(..., samesite="Lax")` preserves `SameSite=Lax`.
- `delete_cookie(..., samesite="None")` preserves `SameSite=None` and sets
  `Secure`.
- messages cookie deletion preserves `settings.SESSION_COOKIE_SAMESITE`.
- session cookie deletion preserves `settings.SESSION_COOKIE_SAMESITE`.
