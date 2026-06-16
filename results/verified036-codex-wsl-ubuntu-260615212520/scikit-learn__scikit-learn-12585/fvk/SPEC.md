# FVK Specification

Status: constructed, not machine-checked. No tests, Python code, or K tooling
were executed.

## Scope

The audited production paths are:

- `repo/sklearn/base.py::clone`
- `repo/sklearn/base.py::BaseEstimator.get_params`
- `repo/sklearn/utils/metaestimators.py::_BaseComposition._get_params`

The observable property under audit is whether an estimator class used as a
parameter value is treated as a plain value, while estimator-like non-class
objects remain recursively cloneable/expandable.

## Intent Spec

I1. `clone` must not raise when an estimator instance has a parameter whose
value is an estimator class.

I2. A class value that exposes `get_params` through its estimator class must not
be treated as an estimator instance. The implementation must not call unbound
`Class.get_params(...)` while cloning or expanding that value.

I3. Estimator-like non-class objects with `get_params`, including objects not
derived from `BaseEstimator`, must continue to be supported.

I4. `get_params(deep=True)` should expand nested estimator instances, but should
leave estimator classes as ordinary parameter values.

I5. Existing public signatures and the behavior for regular estimator instances
must be preserved.

I6. A class passed directly to `clone(..., safe=True)` is not required by the
issue to be cloned as an estimator instance; preserving the existing
non-estimator error path is acceptable.

## Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "`clone` fails when one or more instance parameters are estimator types (i.e. not instances, but classes)." | Class-valued estimator parameters are in domain. | Encoded by C1, C3, C4. |
| E2 | prompt | `clone(StandardScaler(with_mean=StandardScaler))` with "Expected Results: No error." | Recursive parameter cloning must not call `StandardScaler.get_params` as an unbound method. | Encoded by C1. |
| E3 | prompt | Proposed guard: `... or isinstance(estimator, type)` | A type/class with `get_params` should follow the non-estimator branch for recursive parameter cloning. | Encoded by C1 and C5. |
| E4 | public hint | "We need to support non-estimators with get_params, such as Kernel, so `isinstance(obj, BaseEstimator)` is not appropriate." | The discriminator cannot be `BaseEstimator`; non-class `get_params` objects remain estimator-like. | Encoded by C2. |
| E5 | `BaseEstimator.get_params` docstring | "If True, will return the parameters for this estimator and contained subobjects that are estimators." | Deep expansion applies to estimator subobjects/instances, not estimator classes. | Encoded by C3. |
| E6 | composition public API | `Pipeline.get_params`, `FeatureUnion.get_params`, and `VotingClassifier.get_params` delegate to `_BaseComposition._get_params`. | Named estimator expansion must use the same class-vs-instance distinction. | Encoded by C4. |

## Formal Spec English

C1. For any estimator class value `C` encountered during recursive parameter
clone with `safe=False`, `clone` follows the non-estimator fallback and returns a
deep-copied class value without calling `C.get_params`.

C2. For any non-class object that has `get_params`, including a kernel-like
object outside `BaseEstimator`, `clone` still follows the estimator-cloning path.

C3. For any direct parameter value `C` that is a class, `BaseEstimator.get_params`
with `deep=True` includes `param -> C` and emits no `param__...` nested entries
for `C`.

C4. For any named composition entry `(name, C)` where `C` is a class,
`_BaseComposition._get_params(..., deep=True)` includes `name -> C` and emits no
`name__...` nested entries for `C`.

C5. For a class value passed directly to `clone` with `safe=True`, the function
continues to follow the non-estimator error path.

## Spec Audit

| Claim | Adequacy result | Rationale |
| --- | --- | --- |
| C1 | Pass | Directly entails E1, E2, and E3. |
| C2 | Pass | Required by E4; avoids an over-tight `BaseEstimator` check. |
| C3 | Pass | Required by E1 and E5; otherwise `get_params()` still fails on the same unbound method mechanism. |
| C4 | Pass | Required by E1 and E6 once the full public parameter-introspection surface is audited. |
| C5 | Pass | E1/E2 are about class-valued parameters inside estimator instances; no public evidence requires `clone(Class)` with `safe=True` to succeed. |

## Public Compatibility Audit

- `clone` signature unchanged.
- `BaseEstimator.get_params` signature and return type unchanged.
- `_BaseComposition._get_params` signature and return type unchanged.
- Regular estimator instances still satisfy `hasattr(get_params)` and
  `not isinstance(..., six.class_types)`, so their nested parameters are still
  cloned or expanded.
- Non-`BaseEstimator` estimator-like instances with `get_params` still satisfy
  the same non-class predicate, preserving Gaussian-process kernel support.
- Class values now remain ordinary parameter values in all audited public
  parameter-introspection paths.

## K Artifacts

The constructed K core is:

- `fvk/mini-sklearn-clone.k`
- `fvk/clone-params-spec.k`

Commands to run later, not executed in this session:

```sh
kompile fvk/mini-sklearn-clone.k --backend haskell
kast --backend haskell fvk/clone-params-spec.k
kprove fvk/clone-params-spec.k
```
