# FVK Proof

Status: constructed, not machine-checked. No Python code, tests, or K commands
were executed.

## What Is Proved

For the public API slice changed by V1:

- `RidgeClassifierCV(store_cv_values=...)` accepts the keyword and records the
  flag.
- With `store_cv_values=True` and `cv=None`, a successful `fit` reaches the
  existing `_BaseRidgeCV` path that stores `cv_values_` on the public
  classifier object.
- With `store_cv_values=True` and `cv != None`, the existing incompatibility
  error remains.
- With the flag omitted, the default remains `False`.

## Constructed Proof Sketch

1. Constructor dispatch:
   Python keyword binding succeeds because `store_cv_values` is explicit in
   `RidgeClassifierCV.__init__`. The method calls `_BaseRidgeCV.__init__` with
   the same keyword value. `_BaseRidgeCV.__init__` assigns
   `self.store_cv_values = store_cv_values`. This discharges PO-001.

2. Fit path with `cv=None`:
   `RidgeClassifierCV.fit` validates inputs, binarizes labels into `Y`, applies
   class weights when requested, and delegates to `_BaseRidgeCV.fit(self, X, Y,
   sample_weight=sample_weight)`. In `_BaseRidgeCV.fit`, the `cv is None` branch
   constructs `_RidgeGCV(..., store_cv_values=self.store_cv_values)`. After the
   underlying estimator fits, `_BaseRidgeCV.fit` copies
   `estimator.cv_values_` to `self.cv_values_` exactly when
   `self.store_cv_values` is true. This discharges PO-002.

3. Fit path with `cv != None`:
   `_BaseRidgeCV.fit` checks `if self.store_cv_values` before using
   `GridSearchCV` and raises the existing incompatibility `ValueError`. V1 only
   exposes the flag; it does not alter this guard. This discharges PO-003.

4. Estimator API compatibility:
   scikit-learn's `BaseEstimator._get_param_names` requires explicit
   constructor parameters and `get_params` retrieves attributes of those names.
   V1 has an explicit `store_cv_values` parameter, and `_BaseRidgeCV.__init__`
   sets the matching attribute. Appending the parameter after `class_weight`
   preserves previous positional argument meanings. This discharges PO-004.

There are no loops in the changed control-flow slice, so no loop circularity is
needed. The proof is partial with respect to the existing numerical fitting
implementation: if that inherited fit path returns normally on an in-domain
input, the flag-storage postcondition holds.

## Residual Risk

- The proof is constructed, not machine-checked.
- The mini semantics abstracts away full Python execution and the numerical
  ridge algorithm. It preserves the property under test: keyword acceptance,
  flag propagation, incompatible-`cv` behavior, and public `cv_values_`
  presence.
- Termination and numerical correctness of `_RidgeGCV.fit` are not proved.

## Test Guidance

Do not delete tests based on this proof. The existing public tests for
`RidgeCV(store_cv_values=True)` are not redundant for `RidgeClassifierCV`
because they cover a different public class. A focused future test would
construct `RidgeClassifierCV(store_cv_values=True)`, fit it with `cv=None`, and
assert `cv_values_` exists.

## Reproduce the Machine Check Later

The following commands are intentionally recorded but not run:

```sh
cd fvk
kompile mini-python.k --backend haskell
kast --backend haskell ridge-classifier-cv-spec.k
kprove ridge-classifier-cv-spec.k
```

Expected result after a successful machine check: `#Top`.
