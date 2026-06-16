# Iteration Guidance

Status: constructed, not machine-checked.

## Code decision

V1 should not stand exactly as written because Finding F1 showed a positional
compatibility regression. V2 keeps the V1 behavioral fix but moves
`warm_start=False` to the end of the `IsolationForest.__init__` signature after
`verbose=0`.

## Next actions already applied

- Preserve `IsolationForest(warm_start=True)` support.
- Preserve default `warm_start=False`.
- Preserve old positional argument mapping through `verbose`.
- Keep the fix scoped to `repo/sklearn/ensemble/iforest.py`.
- Do not edit tests.

## Suggested future tests

These are recommendations only; test files were not edited.

- Constructor accepts `IsolationForest(warm_start=True)`.
- `IsolationForest(warm_start=True).get_params()["warm_start"]` is `True`.
- Repeated fitting with `warm_start=True` and increased `n_estimators` appends
  estimators using inherited `BaseBagging` behavior.
- A positional compatibility test could instantiate an old positional call and
  assert that `n_jobs`, `behaviour`, `random_state`, and `verbose` are not
  shifted.

## No further code changes recommended

No finding requires adding IsolationForest-specific fitting logic or changing
documentation outside the class docstring. The user-guide example mention in
the original issue was explicitly tentative ("possibly also mention") and is
not necessary to satisfy the constructor/API obligation.
