# Public Evidence Ledger

## E1 - Issue Reproduction

- Source: `benchmark/PROBLEM.md`
- Evidence: "`cv=5` runs fine" but passing `splits = cv.split(X, y, groups=groups)`
  to `SequentialFeatureSelector(..., cv=splits)` fails at `seq.fit(X, y)`.
- Obligation: a generator-like iterable of splits must work for a single SFS
  fit instead of being consumed after the first candidate.
- Status: encoded in `SPEC.md`, `sfs-cv-spec.k`, and proof obligation PO-1.

## E2 - Expected Result

- Source: `benchmark/PROBLEM.md`
- Evidence: "Expected to run without errors."
- Obligation: later scoring calls in the same fit must not encounter an empty
  split sequence solely because a one-shot iterable was already consumed.
- Status: encoded in PO-2, PO-3, PO-4, and the `SFS-FIT-ONESHOT` claim.

## E3 - Public Hint About Root Cause

- Source: `benchmark/PROBLEM.md`
- Evidence: "If `cv` is a generator, it will be consumed at the first iteration
  only."
- Obligation: the proof must model candidate scoring as repeated calls over one
  CV value and distinguish one-shot from reusable split sources.
- Status: encoded in `mini-sfs-cv.k` via `rawFit` versus `fit`.

## E4 - Public Hint About Intended Mechanism

- Source: `benchmark/PROBLEM.md`
- Evidence: "we could call `check_cv` on `self.cv` and transform it into a list
  if it is a generator."
- Obligation: normalize `self.cv` once per fit before repeated candidate scoring.
- Status: encoded in V1 source and PO-2/PO-3.

## E5 - Public Hint About API Consistency

- Source: `benchmark/PROBLEM.md`
- Evidence: "`check_cv` already accepts an iterable, and we don't warn on other
  classes such as `GridSearchCV`."
- Obligation: do not reject generators or add a new warning; use existing CV
  normalization semantics.
- Status: encoded in PO-5 and the decision to leave parameter validation
  unchanged.

## E6 - SFS Docstring

- Source: `repo/sklearn/feature_selection/_sequential.py`
- Evidence: `cv` may be "An iterable yielding (train, test) splits as arrays of
  indices."
- Obligation: SFS must accept iterable splits.
- Status: encoded in PO-1.

## E7 - Parameter Validation

- Source: `repo/sklearn/utils/_param_validation.py`
- Evidence: `_CVObjects` includes `_IterablesNotString()`.
- Obligation: a non-string iterable split source is a valid `cv` parameter.
- Status: encoded in PO-1 and compatibility audit.

## E8 - `check_cv` Implementation

- Source: `repo/sklearn/model_selection/_split.py`
- Evidence: a CV value without `split` that is an iterable is returned as
  `_CVIterableWrapper(cv)`, and that wrapper stores `self.cv = list(cv)`.
- Obligation: once `check_cv` is called, repeated `.split(...)` calls iterate a
  stored list rather than the original generator.
- Status: encoded in PO-3 and the `checkCv(oneShot(S)) => checked(S)` rule.

## E9 - `cross_val_score`/`cross_validate` Implementation

- Source: `repo/sklearn/model_selection/_validation.py`
- Evidence: `cross_validate` calls `check_cv(cv, y, classifier=...)`, then
  obtains `indices = cv.split(X, y, groups)`.
- Obligation: passing an already checked splitter-like object into
  `cross_val_score` is stable because `check_cv` returns objects with `split`
  unchanged.
- Status: encoded in PO-4 and PO-5.

## E10 - SearchCV Comparison

- Source: `repo/sklearn/model_selection/_search.py`
- Evidence: `BaseSearchCV.fit` computes `cv_orig = check_cv(self.cv, y, ...)`
  once and reuses `cv_orig` for candidate evaluation.
- Obligation: SFS should normalize CV once per fit, not once per candidate.
- Status: encoded in PO-2 and the V1 source decision.
