# Constructed Proof

Status: constructed, not machine-checked.

## Claims

The proof uses `fvk/mini-python.k` and `fvk/linkcheck-spec.k`.

- `LC-HTTP-ERROR-FIRST`: ordinary HTTP errors return `resultBrokenHttp` with `anchorChecks = 0`.
- `LC-401-PRESERVED`: 401 returns `resultWorkingUnauthorized` with `anchorChecks = 0`.
- `LC-503-PRESERVED`: 503 returns `resultIgnoredHttp` with `anchorChecks = 0`.
- `LC-OK-MISSING-ANCHOR`: successful missing-anchor responses return `resultBrokenAnchor` with `anchorChecks = 1`.
- `LC-OK-FOUND-SAME-URL`: successful found-anchor same-URL responses return `resultWorking` with `anchorChecks = 1`.
- `LC-OK-FOUND-REDIRECT`: successful found-anchor redirected responses return `resultRedirected` with `anchorChecks = 1`.

## Proof Sketch

The reduced semantics has one rewrite rule per status/anchor classification case and no loops or recursion.

For `LC-HTTP-ERROR-FIRST`, symbolic execution starts with:

```k
<k> checkAnchorBranch(statusHttpError, A, R) </k>
<anchorChecks> 0 </anchorChecks>
```

The HTTP-error rule rewrites the `<k>` cell to `resultBrokenHttp` and leaves `anchorChecks` unchanged. This matches the claim post-state for all `A:AnchorState` and `R:RedirectState`. Because `anchorChecks` remains zero, the proof records that anchor parsing is not reached before the HTTP error result.

For `LC-401-PRESERVED` and `LC-503-PRESERVED`, the matching status rules rewrite directly to `resultWorkingUnauthorized` and `resultIgnoredHttp`, respectively, also preserving `anchorChecks = 0`.

For the successful-response claims, the statusOK rules rewrite to the existing anchor outcomes and increment `anchorChecks` from 0 to 1. This discharges the preservation obligations for successful missing-anchor, working, and redirected cases.

No circularity is required because the modeled branch has no loop. The actual HTML parser loop is intentionally abstracted behind the independent `anchorFound`/`anchorMissing` input, preserving the observable property under audit.

## Mapping Back To V1 Code

V1 added:

```python
response.raise_for_status()
found = check_anchor(response, unquote(anchor))
```

inside the anchor-enabled GET branch. The inserted call ensures ordinary HTTP errors take the existing `except HTTPError` path before `check_anchor()` can raise `Anchor '<anchor>' not found`. On successful responses, `raise_for_status()` returns normally and the pre-existing anchor behavior continues.

## Machine-Check Commands To Run Later

These commands were not executed in this session:

```sh
cd fvk
kompile mini-python.k --backend haskell
kast --backend haskell linkcheck-spec.k
kprove linkcheck-spec.k
```

Expected machine-check result after the K artifacts are accepted by the toolchain: `#Top`.

## Test Guidance

No tests were modified. After machine-checking, unit tests that only restate `PO-1` through `PO-5` for individual in-domain examples may be considered redundant, but integration tests for linkcheck output, request behavior, redirects, retries, and parser behavior should be kept.
