# Iteration Guidance

Status: constructed for FVK audit, not machine-checked.

## Code Status

V2 addresses the only source-level issue surfaced by the FVK audit: the
deprecated `sklearn.grid_search` duplicate now records and documents
`refit_time_` consistently with `sklearn.model_selection`.

No additional code changes are justified by the current public intent ledger or
proof obligations.

## Suggested Public Tests

Do not edit tests in this benchmark. For a normal development pass, add or keep
tests covering:

- `GridSearchCV(..., refit=True).fit(...)` exposes a nonnegative float
  `refit_time_`;
- `RandomizedSearchCV(..., refit=True).fit(...)` exposes `refit_time_`;
- multi-metric search with `refit="<scorer-name>"` exposes `refit_time_`;
- `refit=False` does not expose `refit_time_`;
- an unsupervised estimator path with `y=None` exposes `refit_time_` after
  successful refit;
- while `sklearn.grid_search` remains public, its deprecated grid and randomized
  search classes expose the same attribute after successful refit.

## Machine-Check Follow-Up

When a K environment exists, run:

```sh
kompile fvk/mini-python-refit.k --backend haskell
kast --backend haskell fvk/searchcv-refit-spec.k
kprove fvk/searchcv-refit-spec.k
```

Only after `kprove` returns `#Top` should any tests that are fully subsumed by
the formal claims be considered for removal. Until then, keep the tests.
