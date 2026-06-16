# Formal Spec English

Status: constructed, not machine-checked.

## C-001: Boolean predictors through V1 `fit`

For any valid predictor matrix stored densely or as accepted CSR sparse data,
if its dtype is boolean and it has at least one sample and one feature, the V1
`HuberRegressor.fit` validation path converts it to `float64` before the
gradient operation. The modeled execution finishes this dtype-safety slice with
no boolean-unary-minus error.

## C-002: Floating predictors through V1 `fit`

For any valid predictor matrix stored densely or as accepted CSR sparse data,
if its dtype is already one of `float64`, `float32`, or `float16`, the V1
validation path preserves that floating dtype before the gradient operation.
The modeled execution finishes this dtype-safety slice with no
boolean-unary-minus error.

## C-003: Counterfactual pre-fix localization

If the pre-fix `fit` path forwards a valid boolean predictor matrix to the
gradient operation without floating dtype validation, the gradient operation
reaches the modeled `boolNegativeTypeError`. This is not desired behavior; it
is included to show that the formal model reproduces the public symptom on the
pre-fix mechanism and removes it on V1.

## Frame Conditions

The claims do not change or specify coefficient values, convergence behavior,
target validation beyond existing `check_X_y` behavior, sample-weight semantics,
or estimator parameter checks. Those remain governed by existing source code
and tests outside this dtype-safety proof slice.
