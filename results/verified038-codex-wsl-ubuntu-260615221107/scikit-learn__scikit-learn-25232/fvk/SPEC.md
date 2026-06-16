# FVK Specification

Status: constructed for FVK audit; not machine-checked.

## Target

The target is the V1 fix in `repo/sklearn/impute/_iterative.py`, scoped to:

- the public `IterativeImputer` constructor parameter `fill_value`;
- the internal `SimpleImputer` construction in `_initial_imputation`;
- the feature-validity mask for constant initial imputation, especially
  `fill_value=np.nan`.

The spec is intentionally narrower than full `IterativeImputer` correctness.
It verifies the bug-fix contract required by public intent, not estimator
convergence, numerical predictions, termination, or the whole scikit-learn API.

## Public Intent Ledger

- E-001 requires a public `fill_value` parameter on `IterativeImputer`.
- E-002 and E-003 require forwarding that value to the internal
  `SimpleImputer` when the initialization strategy is constant.
- E-004 requires old defaults to remain unchanged: `fill_value=None` is passed
  through so `SimpleImputer` keeps choosing its existing default.
- E-005 requires `np.nan` to be accepted and not misclassified by
  `IterativeImputer` as an invalid statistic in the constant strategy.
- E-006 limits the `np.nan` claim to `IterativeImputer` allowing the value; the
  chosen estimator remains responsible for accepting missing values.
- E-007 rejects accepting a `SimpleImputer` instance as `initial_strategy` as a
  broader, separate API change.

The detailed ledger is mirrored in `fvk/PUBLIC_EVIDENCE_LEDGER.md`.

## Abstract Model

The K model abstracts only the relevant Python behavior:

- `initIterative(F)` represents constructing an `IterativeImputer` candidate
  with public `fill_value=F` and storing that value on the estimator.
- `makeInitialImputer(S, F)` represents the internal
  `SimpleImputer(strategy=S, fill_value=F)` construction.
- `validMask(S, N, Stats)` represents the `_initial_imputation` decision about
  which of `N` features are valid after the internal imputer has statistics.

The model preserves the property under verification: whether `fill_value` is
available, forwarded, left as `None` by default, and whether a constant
`np.nan` value causes all features to be incorrectly dropped.

## Formal Claims

O-001. Constructor storage:
For every fill value `F`, `initIterative(F)` reaches an object whose stored
`fill_value` is exactly `F`.

O-002. Internal forwarding:
For every strategy `S` and fill value `F`, `makeInitialImputer(S, F)` reaches a
simple-imputer object with strategy `S` and fill value `F`.

O-003. Constant strategy valid-mask rule:
For every feature count `N >= 0` and any statistics list, including all
`NaNFill`, `validMask(constant, N, Stats)` reaches `allIndices(N)`.

O-004. Non-constant frame rule:
For every non-constant strategy and statistics list, `validMask` reaches
`nonNanIndices(Stats, 0)`, preserving the prior empty-feature filtering rule.

O-005. Default-value frame:
`initIterative(NoneFill)` and `makeInitialImputer(constant, NoneFill)` preserve
`NoneFill`; the default constant remains selected by `SimpleImputer`, not by
new `IterativeImputer` code.

## Precondition and Domain

- `N >= 0` for feature counts.
- `Stats` has length `N` where a claim depends on length. The abstract
  functions are total on well-formed lists.
- `F` is any fill value in the model: `NoneFill`, `NaNFill`, or a numeric value.
- `S` is one of `mean`, `median`, `most_frequent`, or `constant`.

## Expected Result

V1 satisfies all obligations above. No production-code change beyond V1 is
justified by this FVK pass.

