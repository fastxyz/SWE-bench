# FVK Iteration Guidance

## Decision

Keep V1 unchanged.

The audit found one real defect, FINDING-F1, and V1 resolves it by discharging
PO-AUTH-PRESERVE and PO-ADAPTER-CONSUMER. The audit did not find a justified
additional source edit.

## Source Guidance

- Do not change `repo/requests/utils.py` beyond V1 for this issue.
- Do not change `repo/requests/sessions.py` for redirect proxy rebuilding in
  this pass. FINDING-F2 explains why that expansion is not intent-derived.
- Do not change tests. The task forbids test edits and the proof is constructed,
  not machine-checked.

## Verification Guidance

When an execution environment is available, run:

```sh
kompile fvk/mini-requests-proxy.k --backend haskell
kast --backend haskell fvk/requests-proxy-spec.k
kprove fvk/requests-proxy-spec.k
```

Expected result:

`#Top`

If the K tooling rejects the lightweight string semantics, repair the formal
artifact syntax first; do not infer a source-code failure from a syntax-level
artifact issue.

## Suggested Public Tests For A Future Test Pass

Do not add these in this benchmark task, but a normal test pass should cover:

- `prepend_scheme_if_needed("http://user:pass@proxy.example:8080", "http")`
  preserves `user:pass@`.
- `prepend_scheme_if_needed("user:pass@proxy.example:8080", "http")` preserves
  `user:pass@` while prepending `http`.
- Existing unauthenticated cases remain unchanged:
  `example.com/path`, `//example.com/path`, and `example.com:80`.
- `HTTPAdapter.proxy_headers` still supports an empty password in
  `http://user:@host`.

## Next Question If Product Scope Expands

If maintainers want scheme-less proxy URLs to be fully supported in every proxy
path despite the docs requiring schemes, ask:

Should `SessionRedirectMixin.rebuild_proxies` normalize `new_proxies[scheme]`
before extracting auth, matching `HTTPAdapter.get_connection`? That is outside
the issue-proven V1 change but is the next coherent expansion point.
