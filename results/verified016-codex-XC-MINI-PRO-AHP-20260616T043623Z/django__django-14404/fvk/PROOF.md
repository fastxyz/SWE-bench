# PROOF

Status: constructed, not machine-checked. No `kompile`, `kast`, or `kprove` commands were run.

## Claims Proved

The K model proves partial correctness for `AdminSite.catch_all_view()` over the modeled branch inputs:

1. CLAIM-REDIRECT: the successful append-slash branch returns `redirect(PATH + "/")`.
2. CLAIM-FORCE-SCRIPT-NAME-WITNESS: for a concrete script-prefixed request, the redirect target includes the script prefix.
3. CLAIM-NO-REDIRECT-APPEND-FALSE: with `APPEND_SLASH=False`, the result is `http404`.
4. CLAIM-NO-REDIRECT-URL-SLASH: with an already slash-terminated captured URL, the result is `http404`.
5. CLAIM-NO-REDIRECT-RESOLVER404: with resolver failure, the result is `http404`.
6. CLAIM-NO-REDIRECT-SHOULD-NOT-APPEND: with a resolved view whose `should_append_slash` is false, the result is `http404`.

There are no loops or recursive calls, so no circularity or termination measure is needed. The model terminates in one rewrite step for each claim.

## Proof Sketch

The mini semantics has one action, `catchAll(APPEND, URLENDS, PATHINFO, PATH, RESOLVE)`, and five deterministic rewrite rules.

For CLAIM-REDIRECT, the initial state has `APPEND=True`, `URLENDS=False`, and `RESOLVE=resolved(True)`. Rule R-REDIRECT applies directly and rewrites the `<k>` cell to `redirect(PATH +String "/")`. By the issue intent and Django's request model, `PATH` is the client-visible path including `SCRIPT_NAME` or `FORCE_SCRIPT_NAME`, so the postcondition preserves the script prefix.

For CLAIM-FORCE-SCRIPT-NAME-WITNESS, instantiate CLAIM-REDIRECT with `PATHINFO="/admin/auth/user"` and `PATH="/script/admin/auth/user"`. The result is `redirect("/script/admin/auth/user/")`, which distinguishes the fixed behavior from the pre-V1 `PATHINFO + "/"` target.

For the non-redirect claims, the corresponding negative rule applies directly:

- R-NO-APPEND when `APPEND=False`.
- R-URL-SLASH when `URLENDS=True`.
- R-RESOLVER404 when the resolver result is `resolver404`.
- R-SHOULD-NOT-APPEND when the resolver result is `resolved(False)`.

Each reaches `http404`, matching the source branch that falls through to `raise Http404`.

## Adequacy

The English meaning of the formal claims matches `INTENT_SPEC.md`: the successful branch redirects to `request.path + "/"`, not to `request.path_info + "/"`; the resolver branch remains tied to `request.path_info + "/"`. `SPEC_AUDIT.md` records all formal obligations as pass.

## Machine-Check Commands

These commands are provided for later checking only; they were not executed in this session.

```sh
cd fvk
kompile mini-django-admin-redirect.k --backend haskell
kast --backend haskell admin-catch-all-spec.k
kprove admin-catch-all-spec.k
```

Expected machine-check result after a working K setup: `#Top` for all claims.

## Test Recommendation

No tests were run and no tests were edited. Because this proof is constructed but not machine-checked, no test removal is recommended. A useful public regression test would cover the F1 witness: admin catch-all missing slash under `FORCE_SCRIPT_NAME` redirects to the script-prefixed `request.path + "/"`.

Existing integration tests around admin authentication, URL resolution, and request path construction should be kept because this proof models only the local branch contract, not the full request stack.
