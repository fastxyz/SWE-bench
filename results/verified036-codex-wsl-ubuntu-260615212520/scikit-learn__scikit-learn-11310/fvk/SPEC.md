# FVK Spec

Status: constructed for FVK audit, not machine-checked.

## Scope

The verified unit is the final-refit tail of `BaseSearchCV.fit`: the branch
entered after candidate search has selected the best parameters. This is the
property-bearing region for issue scikit-learn__scikit-learn-11310 because the
reported missing behavior is an attribute for the final full-data refit
duration, not a change to candidate scoring.

The formal core is:

- `fvk/mini-python-refit.k`
- `fvk/searchcv-refit-spec.k`

The exact machine-check commands, not executed in this benchmark, are:

```sh
kompile fvk/mini-python-refit.k --backend haskell
kast --backend haskell fvk/searchcv-refit-spec.k
kprove fvk/searchcv-refit-spec.k
```

Expected machine-check result after running the commands in an environment with
K installed: `#Top`.

## Public Intent Ledger

The full ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`. Critical entries:

- E1: the issue asks for "Retrieving time to refit the estimator in
  BaseSearchCV", so the obligation attaches to the search fit path.
- E2: the requested measurement is "the time it takes to refit the best model
  on the full data after doing grid/random search".
- E3: the requested public storage location is the exact attribute
  `refit_time_`.
- E4: the issue contrasts this with existing `cv_results_` timing, so the new
  value is final-search metadata, not another per-candidate result.
- E6: model_selection docs define `refit` as fitting the best parameters on the
  whole dataset.
- E7: deprecated `sklearn.grid_search` keeps a duplicate final-refit
  implementation with the same public refit concept while that module remains
  present.

## Formal Claims

`REFIT-TRUE`:
If a validated search reaches the final-refit tail with refit enabled and the
final estimator fit succeeds, the final state contains:

- a fitted `bestEstimator`;
- `fitSawY` equal to whether the supervised `y` argument was present;
- `startSample` equal to the start clock sample;
- `refitTime = TEnd - TStart`, with `TEnd >= TStart`;
- unchanged abstract cross-validation state.

`REFIT-FALSE`:
If refit is false, the final-refit tail terminates without changing
`bestEstimator`, `refitTime`, `fitSawY`, `startSample`, or the abstract
cross-validation state.

## Code Mapping

`repo/sklearn/model_selection/_search.py`:

- imports `time`;
- starts the timer immediately before the final `self.best_estimator_.fit(...)`;
- stores `self.refit_time_` immediately after successful final fit;
- documents the attribute on `GridSearchCV` and `RandomizedSearchCV`.

`repo/sklearn/grid_search.py`:

- imports `time`;
- starts the timer immediately before the deprecated duplicate final
  `best_estimator.fit(...)`;
- stores `self.refit_time_` immediately after successful final fit;
- documents the attribute on deprecated `GridSearchCV` and
  `RandomizedSearchCV`.

## Assumptions

- The proof is partial correctness for normal completion; if final refit raises,
  existing error behavior is preserved and the new attribute is not guaranteed.
- `time.time()` is treated as an elapsed wall-clock source compatible with the
  existing `mean_fit_time` implementation.
- The formal model abstracts clone/set-params as `cloneBest` and excludes that
  step from the measured interval, matching the existing candidate-fit timing
  boundary.
