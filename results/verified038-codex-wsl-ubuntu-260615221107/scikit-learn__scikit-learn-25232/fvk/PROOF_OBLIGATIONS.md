# Proof Obligations

Status: constructed for FVK audit; not machine-checked.

## Obligations

O-001 - Public parameter storage

- Claim: `initIterative(F) => iterativeObj(F)`.
- Intent: I-001.
- Code evidence: `self.fill_value = fill_value`.
- Verification condition: no branch changes or rewrites `F` before storage.
- Status: discharged in the constructed model.

O-002 - Internal `SimpleImputer` forwarding

- Claim: `makeInitialImputer(S, F) => simpleObj(S, F)`.
- Intent: I-002, I-003.
- Code evidence: `SimpleImputer(strategy=self.initial_strategy,
  fill_value=self.fill_value, ...)`.
- Verification condition: the value stored by O-001 is the value passed to the
  internal imputer.
- Status: discharged in the constructed model.

O-003 - `np.nan` constant feature validity

- Claim: for `N >= 0`,
  `validMask(constant, N, constantStats(N, NaNFill)) => allIndices(N)`.
- Intent: I-004.
- Code evidence: `if self.initial_strategy == "constant":
  valid_mask = np.arange(X.shape[1])`.
- Verification condition: the constant branch does not inspect
  `np.isnan(statistics_)`.
- Status: discharged in the constructed model.

O-004 - Non-constant frame condition

- Claim: for `mean`, `median`, and `most_frequent`,
  `validMask(S, N, STATS) => nonNanIndices(STATS, 0)`.
- Intent: I-005.
- Code evidence: the non-constant branch keeps
  `np.flatnonzero(np.logical_not(np.isnan(...)))`.
- Verification condition: only the constant branch changes validity behavior.
- Status: discharged in the constructed model.

O-005 - Default preservation

- Claim: `initIterative(NoneFill) => iterativeObj(NoneFill)` and
  `makeInitialImputer(constant, NoneFill) => simpleObj(constant, NoneFill)`.
- Intent: I-003.
- Code evidence: `fill_value=None` constructor default and direct forwarding.
- Verification condition: `IterativeImputer` does not replace `None` with a
  concrete default; `SimpleImputer` remains the component that interprets it.
- Status: discharged in the constructed model.

## Machine-Check Commands To Run Later

These commands are not executed in this benchmark environment:

```sh
cd fvk
kompile mini-python-impute.k --backend haskell
kast --backend haskell iterative-imputer-spec.k
kprove iterative-imputer-spec.k
```

Expected machine-check result after a working K setup: `kprove` returns `#Top`.

## Residual Risks

- The proof is partial correctness over the abstract bug-fix slice.
- Full Python semantics, NumPy array behavior, and full scikit-learn estimator
  behavior are trusted abstractions.
- Estimator-level `np.nan` support is outside the proof; unsupported estimators
  may still reject `np.nan` during fit or predict.

