# PROOF

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## Machine-check commands not executed

The following are the exact commands to run later in an environment with K
available. They were not run in this session.

```sh
kompile fvk/mini-django-admin.k --backend haskell
kast --backend haskell fvk/admin-catch-all-spec.k
kprove fvk/admin-catch-all-spec.k
```

Expected result after machine checking: `#Top` for all claims.

## Claims Proved Constructively

The constructed proof covers these claims from `fvk/admin-catch-all-spec.k`:

- `CATCH-REDIRECT-PRESERVES-QUERY`: the eligible admin catch-all branch returns
  `Redirect(fullPathSlash(PATH, QUERY))`.
- `FULL-PATH-NONEMPTY-QUERY`: if `QUERY` is non-empty, `fullPathSlash(PATH,
  QUERY)` equals `slashPath(PATH) + "?" + encodedQuery(QUERY)`.
- `FULL-PATH-EMPTY-QUERY`: if `QUERY` is empty, `fullPathSlash(PATH, QUERY)`
  equals `slashPath(PATH)`.
- `CATCH-NO-REDIRECT-WHEN-GATES-FAIL-*`: when a redirect gate fails, the result
  is `Http404`.

## Symbolic Proof Sketch

1. Start from the in-domain redirect state:
   `APPEND_SLASH=True`, `URL_ENDS_SLASH=False`, `SLASH_RESOLVES=True`,
   `SHOULD_APPEND=True`, symbolic `PATH`, and symbolic `QUERY`.
2. The first branch condition in `catch_all_view()` succeeds because
   `APPEND_SLASH` is true and the captured URL does not end in `/`.
3. The resolver branch succeeds by the `SLASH_RESOLVES=True` premise.
4. The `should_append_slash` branch succeeds by the `SHOULD_APPEND=True`
   premise.
5. V1 evaluates the redirect argument as
   `request.get_full_path(force_append_slash=True)`.
6. The helper contract rewrites that expression to `fullPathSlash(PATH, QUERY)`.
7. Case split on `QUERY`:
   - If `QUERY` is empty, `fullPathSlash(PATH, QUERY)` rewrites to
     `slashPath(PATH)`, which is the path with the forced slash and no `?`.
   - If `QUERY` is non-empty, `fullPathSlash(PATH, QUERY)` rewrites to
     `slashPath(PATH) + "?" + encodedQuery(QUERY)`.
8. Therefore every eligible redirect preserves the query string and places it
   after the forced slash.

For non-redirect branches, symbolic execution takes one of the failed gates:
`APPEND_SLASH=False`, `URL_ENDS_SLASH=True`, `SLASH_RESOLVES=False`, or
`SHOULD_APPEND=False`. In all cases the transition reaches `Http404`, matching
the unchanged source branch after the redirect block.

## Counterexample Against Legacy Code

Legacy redirect expression:

```python
HttpResponsePermanentRedirect("%s/" % request.path)
```

Counterexample:

- `PATH="/admin/auth/foo"`
- `QUERY="id=123"`
- all redirect gates true

Legacy result: `/admin/auth/foo/`.

Required result: `/admin/auth/foo/?id=123`.

The legacy expression cannot satisfy `FULL-PATH-NONEMPTY-QUERY` because
`request.path` excludes `QUERY_STRING`.

## Why V1 Discharges the Obligations

V1 changes only the redirect argument:

```python
request.get_full_path(force_append_slash=True)
```

`HttpRequest._get_full_path()` constructs:

```python
escape_uri_path(path)
+ ("/" if force_append_slash and not path.endswith("/") else "")
+ ("?" + iri_to_uri(QUERY_STRING) if QUERY_STRING else "")
```

That expression exactly matches the postconditions for empty and non-empty
queries. Since the surrounding branch gates are unchanged, V1 satisfies the
query preservation obligation without expanding the redirect surface.

## Test Redundancy Recommendation

No test files were inspected or modified beyond source reads allowed by the
task. A future regression test for `/admin/auth/foo?id=123` would be subsumed by
the constructed `FULL-PATH-NONEMPTY-QUERY` claim only after the emitted K claims
are machine-checked. Until `kprove` returns `#Top`, keep such tests.

## Residual Risk

- Constructed, not machine-checked.
- The mini semantics abstracts Django URL resolving and URI encoding internals.
- The proof establishes the redirect-location property and branch preservation,
  not global admin URL routing behavior.
