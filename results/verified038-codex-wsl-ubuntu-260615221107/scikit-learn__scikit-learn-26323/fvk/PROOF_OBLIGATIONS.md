# Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Remainder Estimator Propagation

For any `ColumnTransformer` whose `remainder` is an estimator, a call to
`set_output(transform=t)` with `t != None` must call `_safe_set_output` on
`self.remainder`.

- Evidence: E1, E2, E4.
- Source discharge: `repo/sklearn/compose/_column_transformer.py` now calls
  `_safe_set_output(self.remainder, transform=transform)` when the remainder is
  not `"passthrough"` or `"drop"`.
- Formal discharge: `REMAINDER-PROPAGATED`.

## PO-2: Fit-Time Clone Inherits Remainder Configuration

If `set_output(pandas)` is called before fit, then the remainder estimator clone
used by `_fit_transform` must see pandas output configuration.

- Evidence: E5, E6.
- Source discharge: `self.remainder` is configured before `_fit_transform`
  clones it; `clone` deep-copies `_sklearn_output_config`.
- Formal discharge: `CLONED-REMAINDER-PANDAS`.

## PO-3: Pandas Dense Stacking Branch Is Reachable

For the issue domain, when the explicit transformer output and the remainder
clone output are pandas-configured and the `ColumnTransformer` config is pandas,
`_hstack` must take the pandas concat branch.

- Evidence: E3, E7.
- Source discharge: all active outputs can satisfy `hasattr(X, "iloc")` once
  the remainder clone is configured.
- Formal discharge: `PANDAS-HSTACK`.

## PO-4: `transform=None` Is A No-Op

Calling `_safe_set_output(estimator, transform=None)` must leave configuration
unchanged and must not require `estimator.set_output`.

- Evidence: E8.
- V1 status: failed for estimators with `transform` but no `set_output`.
- V2 source discharge: `_safe_set_output` returns immediately when
  `transform is None`.
- Formal discharge: `NONE-NOOP`.

## PO-5: Non-`None` Error Behavior Is Preserved

Calling `_safe_set_output` with `transform="pandas"` or `"default"` on a
transforming estimator without `set_output` must continue to raise.

- Evidence: E9.
- Source discharge: the `hasattr(estimator, "set_output")` check still runs
  for non-`None` transforms.
- Formal status: recorded as a compatibility obligation; not modeled as an
  exception claim in the mini semantics.

## PO-6: Sentinel Remainders Are Not Estimators

String remainders `"drop"` and `"passthrough"` must not be sent to
`_safe_set_output` as estimators.

- Evidence: E4, E5.
- Source discharge: `ColumnTransformer.set_output` guards with
  `self.remainder not in {"passthrough", "drop"}`.
- Formal discharge: `SENTINEL-UNCHANGED`.
