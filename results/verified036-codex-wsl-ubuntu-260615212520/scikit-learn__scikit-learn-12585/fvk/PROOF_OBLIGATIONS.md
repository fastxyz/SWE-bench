# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO-1 - Recursive clone of class-valued parameter

Linked findings: F-001.

Claim: For every class object `C` with `hasGetParams(C) == true` and
`isClass(C) == true`, the recursive parameter call `clone(C, safe=False)` takes
the non-estimator fallback path and returns `copy.deepcopy(C)`. It must not call
`C.get_params`.

K claim: `CloneParam(classObj(C), false) => ObjResult(classObj(C))`.

Code obligation:

```python
elif (not hasattr(estimator, 'get_params') or
      isinstance(estimator, six.class_types)):
```

## PO-2 - Non-class `get_params` objects remain supported

Linked findings: F-001.

Claim: For every non-class object `O` with `hasGetParams(O) == true`,
`clone(O, safe=False)` still follows the estimator-like cloning path. This
includes non-`BaseEstimator` objects such as Gaussian-process kernels.

K claim: `CloneParam(kernelObj(K, P), false) => EstimatorClone(kernelObj(K, P))`.

Code obligation: the predicate excludes only class objects; it does not require
`isinstance(O, BaseEstimator)`.

## PO-3 - `BaseEstimator.get_params(deep=True)` with class-valued direct parameter

Linked findings: F-001.

Claim: For any direct parameter `param -> C` where `C` is a class,
`get_params(deep=True)` includes the direct entry and does not attempt nested
expansion by calling `C.get_params`.

K claim: `DeepParamEntry(PNAME, classObj(C)) => IncludeOnly(PNAME, classObj(C))`.

Code obligation:

```python
if (deep and hasattr(value, 'get_params') and
        not isinstance(value, six.class_types)):
```

## PO-4 - Composition deep parameter expansion with class-valued named entry

Linked findings: F-002.

Claim: For any `_BaseComposition` named entry `(name, C)` where `C` is a class,
`_get_params(..., deep=True)` includes `name -> C` and does not call
`C.get_params(deep=True)`.

K claim: `CompositionEntry(NAME, classObj(C)) => IncludeOnly(NAME, classObj(C))`.

Code obligation:

```python
if (hasattr(estimator, 'get_params') and
        not isinstance(estimator, six.class_types)):
```

## PO-5 - Compatibility frame conditions

Linked findings: F-003, F-004.

Claims:

- Public function signatures are unchanged.
- Regular estimator instances still recurse/expand.
- Non-`BaseEstimator` get-params instances still recurse/expand.
- Top-level `clone(C, safe=True)` for a class value remains on the TypeError
  path because the issue only requires class-valued parameters to clone.

K claim: `CloneParam(classObj(C), true) => TypeError`.
