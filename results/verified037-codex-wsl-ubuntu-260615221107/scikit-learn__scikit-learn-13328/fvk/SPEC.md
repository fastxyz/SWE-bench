# FVK Spec

Status: constructed, not machine-checked.

## Target

Public unit under audit:

```python
HuberRegressor.fit(self, X, y, sample_weight=None)
```

The formal slice covers the validation handoff that determines the dtype of
`X` passed into `_huber_loss_and_gradient`. This is the behavioral contributor
that produces the reported TypeError when `X` remains boolean.

## Intent Ledger

| ID | Evidence | Obligation |
| --- | --- | --- |
| L-001 | E-001, E-002 | Valid boolean predictor matrices are in-domain for `HuberRegressor.fit`; fitting them must not raise the boolean-unary-minus TypeError. |
| L-002 | E-003 | Boolean `X` must be converted to a floating dtype by `fit` before the optimizer/loss path. |
| L-003 | E-004 | Already-floating `X` must keep the previously working path. |
| L-004 | E-006 | Because `fit` accepts CSR sparse input, accepted sparse boolean matrices must get the same dtype safety. |
| L-005 | E-008 | No public signature or unrelated validation behavior should change. |

## Formal Model

The `.k` model abstracts a predictor matrix by:

- storage kind: `dense` or accepted `csr`;
- dtype: `bool`, integer, or one of `float64`, `float32`, `float16`;
- positive shape dimensions.

The model keeps dtype as an observable because dtype is the axis manipulated by
the fix and measured by the issue. It abstracts away actual coefficients,
target values, and L-BFGS-B iterations because those are not needed to
distinguish the reported failure from the expected behavior.

The K transition `fitV1(matrix(S, DT, R, C))` represents the V1
`check_X_y(..., dtype=FLOAT_DTYPES)` call followed by entry into the gradient
operation. If `DT` is not in `FLOAT_DTYPES`, the transition records
`validatedDType = float64` before `gradientSquared`. If `DT` is already a
floating dtype, it records the same dtype. `gradientSquared` raises
`boolNegativeTypeError` only when it receives a boolean matrix.

## Claims

C-001: For every valid dense or accepted CSR boolean predictor matrix,
`fitV1` validates `X` to `float64` and reaches the downstream gradient with
`error = noError`.

C-002: For every valid dense or accepted CSR predictor matrix whose dtype is in
`FLOAT_DTYPES`, `fitV1` preserves that floating dtype and reaches the downstream
gradient with `error = noError`.

C-003: The counterfactual pre-fix model `fitV0`, which forwards `X` to the
gradient without float dtype validation, reaches `boolNegativeTypeError` for a
valid boolean predictor matrix. This localizes the original failure mechanism.

## Preconditions

P-001: `X` has at least one sample and one feature. This follows the existing
default `check_X_y` shape domain and is not changed by V1.

P-002: `X` is dense or accepted CSR sparse input. Other sparse formats are
outside the existing `HuberRegressor.fit` sparse policy.

P-003: `y`, `sample_weight`, and estimator parameters satisfy existing
preconditions. These are frame conditions for this dtype-specific audit.

## Postconditions

Q-001: Boolean `X` entering `fit` is not boolean when the gradient path applies
unary minus to a row slice.

Q-002: The specific TypeError reported in the issue is unreachable through the
public `fit` path for valid boolean `X`.

Q-003: For already-floating `X`, the dtype validation path does not force a new
dtype outside `FLOAT_DTYPES`.

## Adequacy Boundary

This FVK pass proves the dtype-safety slice needed for the reported bug. It
does not prove convergence, optimality, coefficient equality, warning behavior,
or termination of the SciPy optimizer. Existing numerical and integration tests
remain necessary.
