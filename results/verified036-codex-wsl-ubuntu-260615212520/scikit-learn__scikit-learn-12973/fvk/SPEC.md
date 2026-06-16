# FVK Spec: LassoLarsIC copy_X Routing

Status: constructed, not machine-checked. No tests, Python code, or K tooling were run.

## Scope

This FVK pass audits the public issue's behavioral surface: how `LassoLarsIC.fit` resolves and routes `copy_X` to its two copy-sensitive downstream operations. It does not attempt to prove numerical LARS/AIC/BIC correctness.

The verified abstraction is:

`fitRoute(self_copy, fit_copy_arg) -> (preprocess_copy, lars_path_copy)`

where `fit_copy_arg` is either `None`, `True`, or `False`. The first result is the copy value passed to `LinearModel._preprocess_data`; the second is the copy value passed to `lars_path`.

## Intent-Only Spec

1. `LassoLarsIC` has a constructor-level `copy_X` setting.
2. `fit` must not silently override the constructor setting when the caller omits `copy_X`.
3. `fit` may keep accepting a per-call `copy_X` argument for backward compatibility.
4. When the per-call argument is omitted or `None`, both downstream copy-sensitive operations must use `self.copy_X`.
5. When the per-call argument is explicitly `True` or `False`, both downstream copy-sensitive operations must use that explicit value.
6. A single `fit` call must not use contradictory `copy_X` values internally.
7. The fix should not otherwise change validation, model-selection, path computation, or learned-attribute behavior.

## Public Evidence Ledger

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "`LassoLarsIC` accepts a `copy_X` parameter" | Constructor setting is public intent evidence. | Encoded in O1/O2. |
| E2 | `benchmark/PROBLEM.md` | "`fit` takes a default value of `None`" | Default method binding should be `None`, not `True`. | Encoded by source line 1482 and K claim `None`. |
| E3 | `benchmark/PROBLEM.md` | "only overwrites the existing value if the user has explicitly passed it" | Omitted/`None` method argument uses `self.copy_X`; explicit boolean overrides for this fit. | Encoded in O1/O2. |
| E4 | `benchmark/PROBLEM.md` | "two values (potentially contradicting each other) ... each one is used once" | Both downstream operations must receive the same resolved value. | Encoded in O1/O2. |
| E5 | `benchmark/PROBLEM.md` | "removing `copy_X` from `fit` ... would break existing code" | Keep accepting `fit(..., copy_X=...)`. | Compatibility obligation O3. |
| E6 | Source | `lars_path` copies `X` when its `copy_X` argument is true (`least_angle.py:174-180`). | The routed value is behaviorally observable as copy vs in-place path behavior. | Supports model observable. |
| E7 | Source | `_preprocess_data` passes `copy` into `check_array` and copies when requested (`base.py:116-123`). | The routed value is behaviorally observable in preprocessing. | Supports model observable. |

## Formal Spec English

O1. For every boolean constructor value `C`, `fitRoute(C, None)` returns `(C, C)`.

O2. For every constructor value `C` and every explicit boolean fit value `F`, `fitRoute(C, F)` returns `(F, F)`.

O3. The public method still accepts a third `copy_X` argument; changing the default from `True` to `None` is intentional and required by E2/E3.

O4. Other fit behavior is framed: the only audited source behavior changed is the resolution and downstream routing of `copy_X`, plus docstring precision for the accepted `None` sentinel.

## Adequacy Audit

| Obligation | Intent match | Rationale |
| --- | --- | --- |
| O1 | Pass | Directly captures E2/E3 and the reported `LassoLarsIC(copy_X=False).fit(X, y)` scenario. |
| O2 | Pass | Captures backward-compatible explicit per-call override and prevents mixed behavior from E4. |
| O3 | Pass | Captures E5: keep the public fit argument rather than removing it. |
| O4 | Pass | The diff is limited to the `copy_X` default, resolution, downstream argument, and docstring wording. |

## Public Compatibility Audit

Changed public symbol: `LassoLarsIC.fit(self, X, y, copy_X=None)`.

Compatibility result:

- Existing `fit(X, y)` callers still call successfully; the behavior intentionally changes to honor the constructor setting.
- Existing `fit(X, y, True)` and `fit(X, y, False)` callers still call successfully and now route the explicit value consistently.
- Local search found no in-repo subclass of `LassoLarsIC` and no in-repo public callsite passing `copy_X` to `LassoLarsIC.fit`.
- No test file was modified.

## Formal Artifacts

The constructed mini-K model is in `fvk/mini-copy-routing.k`.

The constructed K claims are in `fvk/lasso-lars-ic-copy-x-spec.k`.

Expected machine-check commands, not executed:

```sh
cd fvk
kompile mini-copy-routing.k --backend haskell
kast --backend haskell lasso-lars-ic-copy-x-spec.k
kprove lasso-lars-ic-copy-x-spec.k
```
