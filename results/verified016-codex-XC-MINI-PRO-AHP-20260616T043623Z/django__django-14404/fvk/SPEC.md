# SPEC

Status: constructed FVK spec for V1, not machine-checked.

## Scope

The verified unit is `AdminSite.catch_all_view(request, url)` in `repo/django/contrib/admin/sites.py`, after the surrounding `admin_view()` authorization wrapper has allowed the request to reach the view.

The observable under audit is whether the view returns an `HttpResponsePermanentRedirect` and what redirect target it uses, or raises `Http404`.

## Public Intent Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| I1 | prompt issue | "`catch_all_view() does not support FORCE_SCRIPT_NAME.`" | A missing-slash admin redirect must preserve the script prefix configured by `FORCE_SCRIPT_NAME`. | Encoded in CLAIM-REDIRECT and CLAIM-FORCE-SCRIPT-NAME-WITNESS. |
| I2 | prompt issue | "`catch_all_view returns redirect to '%s/' % request.path_info (script name cut off there) instead of '%s/' % request.path (with the script name)`" | On the successful append-slash branch, the redirect target is `request.path + "/"`, not `request.path_info + "/"`. | Encoded in CLAIM-REDIRECT. |
| I3 | public request tests | `request.path` is expected to be `/FORCED_PREFIX/somepath/` under `FORCE_SCRIPT_NAME`. | `request.path` is the client-visible path that includes the forced script prefix. | Supports CLAIM-FORCE-SCRIPT-NAME-WITNESS. |
| C1 | source code | `WSGIRequest` builds `self.path` from `script_name.rstrip("/")` plus `path_info`. | The implementation-level relationship is `path = script_name + path_info`, normalized for one slash; `path_info` remains the resolver path. | Modeled as distinct symbolic strings `PATH` and `PATHINFO`. |
| C2 | source code | `catch_all_view()` calls `resolve(path, urlconf)` where `path = "%s/" % request.path_info`. | Resolver lookup must keep using the script-stripped path candidate `request.path_info + "/"`. | Encoded as the `resolved(true)` input being the result of resolving `PATHINFO + "/"`; PO-2 preserves this. |
| C3 | public admin behavior | Existing admin catch-all tests cover `APPEND_SLASH=True` redirecting valid slash-appended admin URLs and 404 otherwise. | Redirect only when `APPEND_SLASH` is true, the captured URL is missing `/`, the slash-appended resolver lookup succeeds, and the target view allows append-slash. Otherwise raise `Http404`. | Encoded in negative claims CLAIM-NO-REDIRECT-*. |

## Contract

Let:

- `APPEND` be `settings.APPEND_SLASH`.
- `URLENDS` be whether the captured `url` argument ends with `/`.
- `PATHINFO` be `request.path_info`.
- `PATH` be `request.path`.
- `RESOLVE` be the result of resolving `PATHINFO + "/"` against the active URLconf.

Postconditions:

1. If `APPEND == True`, `URLENDS == False`, and `RESOLVE == resolved(True)`, `catch_all_view()` returns `HttpResponsePermanentRedirect(PATH + "/")`.
2. If `APPEND == False`, or `URLENDS == True`, or resolving `PATHINFO + "/"` raises `Resolver404`, or the resolved view has `should_append_slash == False`, `catch_all_view()` raises `Http404`.

Frame conditions:

- The method signature and caller protocol are unchanged.
- URL resolution remains based on `request.path_info + "/"`, not `request.path + "/"`.
- The spec does not add query-string preservation because the public issue identifies `request.path`, not `request.get_full_path()`, as the intended redirect source.

## Formal Core

The formal artifacts are:

- `fvk/mini-django-admin-redirect.k`: minimal K fragment for the branch structure and redirect observable.
- `fvk/admin-catch-all-spec.k`: K reachability claims for the redirect and non-redirect branches.

No loops or recursion occur in this unit, so there are no circularity obligations.
