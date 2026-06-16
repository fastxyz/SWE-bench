# FVK Iteration Guidance

Status: V2 keeps V1 behavior and adds docstring precision.

## Code Decision

Keep the V1 behavioral fix. The FVK obligations PO-1, PO-2, and PO-3 show that V1 resolves the public issue's core defect: there is exactly one effective `copy_X` value per fit call, and it is routed consistently.

Apply the V2 docstring refinement from F-003/PO-5. Since `None` is now both the default and an accepted sentinel, the public parameter type should read `boolean or None`.

## Rejected Alternatives

Remove `copy_X` from `fit`: rejected by E5/PO-4 because the issue explicitly notes this would break existing code.

Leave `_preprocess_data` on `self.copy_X` while changing only the default: rejected by F-002/PO-2 because explicit fit-level overrides would still route mixed values.

Mutate `self.copy_X` inside `fit` when an explicit value is passed: not required by the public intent and not needed to close any proof obligation. The obligation is per-call routing consistency, not permanent estimator hyperparameter mutation.

## Next Tests To Add In A Normal Development Environment

Do not edit tests in this benchmark task. In normal development, add focused tests or monkeypatch checks for:

- omitted `fit` argument with constructor `copy_X=False`;
- explicit `fit(copy_X=False)` with constructor `copy_X=True`;
- explicit `fit(copy_X=None)` with constructor `copy_X=False`.

## Verification Commands To Run Later

Do not run these in this task. In an environment with K installed:

```sh
cd fvk
kompile mini-copy-routing.k --backend haskell
kast --backend haskell lasso-lars-ic-copy-x-spec.k
kprove lasso-lars-ic-copy-x-spec.k
```

In an environment with the project test dependencies installed, run the relevant linear-model tests after adding public tests for the routed values.
