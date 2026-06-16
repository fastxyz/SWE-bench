# Iteration Guidance

## Decision

V1 stands unchanged. The FVK audit found the original V1 edit exactly matches
the public intent and proof obligations for the issue.

## Source Changes In This Iteration

No production source files under `repo/` were changed during the FVK iteration.
The existing V1 source edit remains:

- `repo/sphinx/builders/linkcheck.py` imports `TooManyRedirects`;
- the inner HEAD fallback handler catches `(HTTPError, TooManyRedirects)`.

## Why No Additional Code Change

- Do not broaden to all Requests exceptions: Finding F-003 and PO-06 show the
  public intent only justifies `TooManyRedirects` plus the existing HTTPError
  fallback.
- Do not change anchor behavior: the intent and PO-01 scope are non-anchor HEAD
  fallback; anchor checks already use GET for content inspection.
- Do not change GET failure behavior: Finding F-004 and PO-05 show that if the
  fallback GET also raises `TooManyRedirects`, reporting broken is still the
  existing and intended outcome.
- Do not change public API/output shape: PO-08 confirms V1 is internal and
  compatible.

## Recommended Next Work

- Add a public test, when test editing is allowed, for HEAD
  `TooManyRedirects` followed by successful GET classification.
- Run the recorded K commands when a K environment is available:

```sh
cd fvk
kompile mini-linkcheck.k --backend haskell
kast --backend haskell linkcheck-spec.k
kprove linkcheck-spec.k
```

Keep all existing integration tests unless a future machine-checked proof plus
maintainer review specifically justifies removing a narrow unit-style test.
