# Iteration Guidance

Status: constructed, not machine-checked.

## Decision

Keep V1 unchanged. The FVK findings identify the pre-V1 defect and show that the one-line V1 edit discharges the relevant proof obligations without introducing a compatibility problem.

## No Further Source Edit

No additional production-code edit is justified by the FVK artifacts:

- `F-1` is resolved by `PO-1` and `PO-2`.
- `F-2` confirms V1 preserves successful missing-anchor behavior through `PO-4`.
- `F-3` confirms V1 routes 401 and 503 through the existing policy via `PO-3`.
- `PO-6` confirms there is no public API or output-schema compatibility gap.

## Suggested Tests For A Future Test Pass

Do not edit tests in this benchmark task. For a normal development pass, add focused tests with mocked responses:

- URI `https://example.invalid/missing#frag`, GET status 404, body lacks `frag` -> `broken` with HTTPError text, not anchor text.
- URI with status 500 and missing anchor -> `broken` with HTTPError text.
- URI with status 401 and an anchor -> `working` unauthorized policy.
- URI with status 503 and an anchor -> `ignored` policy.
- URI with status 200 and missing anchor -> still `Anchor '<anchor>' not found`.
- URI with status 200, found anchor, and redirect history -> still redirected with the original anchor appended.

## Machine-Check Follow-Up

The constructed K proof should be machine-checked later with:

```sh
cd fvk
kompile mini-python.k --backend haskell
kast --backend haskell linkcheck-spec.k
kprove linkcheck-spec.k
```

Until `kprove` returns `#Top`, treat the proof as constructed evidence rather than machine verification, and do not remove tests based on it.
