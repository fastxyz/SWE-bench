# Intent Specification

Status: constructed, not machine-checked.

## Required behavior

1. `IsolationForest.__init__` exposes a public `warm_start` parameter with
   default value `False`.
2. Passing `warm_start=True` at construction configures the inherited
   `BaseBagging` warm-start behavior, so later `fit` calls can reuse prior
   estimators and add more estimators when `n_estimators` is increased.
3. Omitting `warm_start` preserves the previous default behavior:
   `warm_start=False`.
4. The parameter is documented with the same semantic wording used by the
   forest estimators: when true, reuse the previous fit and add more
   estimators; otherwise fit a new forest.
5. The API change should preserve existing public constructor usage. In
   particular, adding a new optional parameter must not remap the old positional
   parameters `n_jobs`, `behaviour`, `random_state`, and `verbose`.

## Out of scope

- Reimplementing warm-start fitting logic inside `IsolationForest`. Public
  intent says the existing inherited behavior works.
- Modifying tests. The benchmark instructions forbid editing test files.
- Machine-checking the K artifacts. This environment forbids running K tooling.
