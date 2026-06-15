# FVK Notes

## Summary

The FVK audit confirmed the V1 production-code fix and found one additional
public API documentation gap. V2 updates `docs/ref/request-response.txt`; the
runtime source changes from V1 stand unchanged.

## Decisions

1. Keep `HttpResponseBase.delete_cookie(..., samesite=None)`.

   Reason: `F1` identifies SameSite preservation as the core reported defect,
   and `PO1`/`PO2` show the V1 method now sends the explicit `samesite` value
   through to `set_cookie()` while preserving the existing expiration behavior.

2. Keep the `SameSite=None` secure handling in `delete_cookie()`.

   Reason: `F2` traces the browser rejection risk from the public issue, and
   `PO3` requires `Secure` when SameSite is `None` while preserving existing
   secure-prefix behavior.

3. Keep the messages and sessions call-site updates from V1.

   Reason: `F4` shows that adding a core `samesite` argument alone would not
   fix the reported messages path unless built-in callers passed their
   configured value. `PO4` and `PO5` discharge those call-site obligations.

4. Update `repo/docs/ref/request-response.txt`.

   Reason: `F3` found that V1 changed a public method signature while leaving
   the public docs stale. `PO6` requires source and docs to expose the same
   public API. The V2 edit updates the method signature, says `samesite` should
   match the value used with `set_cookie()`, and adds a 3.2 versionchanged note.

5. Do not add session-specific defaults to the core response method.

   Reason: `PO2` models `samesite` as an explicit caller-provided value, while
   `PO4` and `PO5` put `SESSION_COOKIE_SAMESITE` only at the messages and
   sessions call sites that already use that setting. This rejects the issue
   reporter's experimental use of session settings inside `delete_cookie()` for
   all cookies.

6. Do not add `secure` or `httponly` parameters to `delete_cookie()` in this
   iteration.

   Reason: `PO1` and `PO3` cover the deletion attributes required by the public
   issue: expiration targeting, SameSite preservation, secure prefixes, and
   `SameSite=None` requiring `Secure`. `F2` does not require preserving
   arbitrary `secure`/`httponly` inputs to delete a cookie.

7. Do not implement fallback dispatch for hypothetical external overrides.

   Reason: `F5` records this as a residual compatibility risk, but `PO6` found
   no in-repo override and the public hint specifically requires adding the new
   argument. Adding fallback dispatch would be ungrounded in the available
   public source.

8. Keep verification claims conditional.

   Reason: `F6` and `PO7` require honesty about the benchmark constraint: no
   tests, Python, Django code, or K tooling were run. The proof is constructed,
   not machine-checked, and no test-removal recommendation is applied.

## Files changed in V2

`repo/docs/ref/request-response.txt`

- Public signature changed to
  `HttpResponse.delete_cookie(key, path='/', domain=None, samesite=None)`.
- Added guidance that `samesite` should match the value used in
  `set_cookie()`.
- Added `.. versionchanged:: 3.2` for the new argument.

No V2 runtime code changes were needed after the FVK audit.
