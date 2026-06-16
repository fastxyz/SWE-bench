# FVK Spec: RidgeClassifierCV store_cv_values

Status: constructed, not machine-checked. No Python tests, Python snippets, or
K tooling were executed.

## Scope

This audit covers the public API behavior introduced by V1 for
`sklearn.linear_model.RidgeClassifierCV`: accepting the documented
`store_cv_values` keyword, preserving it as estimator state, and making
`cv_values_` available after `fit` when `cv=None`.

The numerical correctness of ridge generalized cross-validation is inherited
from the existing `_BaseRidgeCV` and `_RidgeGCV` implementation. It is outside
this issue's changed behavior and is not re-proved here.

## Intent Spec

- INT-001: `RidgeClassifierCV(..., store_cv_values=True)` must be a valid
  constructor call, not a `TypeError`.
- INT-002: For in-domain classifier inputs accepted by existing
  `RidgeClassifierCV.fit`, `store_cv_values=True` with `cv=None` must make the
  fitted estimator expose cross-validation values through `cv_values_`.
- INT-003: The documented incompatibility with `cv != None` remains: requesting
  `store_cv_values=True` while supplying an explicit `cv` is invalid.
- INT-004: Omitting `store_cv_values` preserves previous behavior, with the flag
  defaulting to `False`.
- INT-005: The change must be compatible with scikit-learn's estimator API:
  constructor parameters are explicit keyword arguments and readable as
  attributes by `BaseEstimator.get_params`.

## Public Evidence Ledger

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| EV-001 | prompt | "TypeError: __init__() got an unexpected keyword argument 'store_cv_values'" | The keyword rejection is the reported bug. | Encoded by INT-001 and PO-001. |
| EV-002 | prompt | "Add store_cv_values boolean flag support to RidgeClassifierCV" | The public constructor needs a boolean flag. | Encoded by INT-001 and PO-001. |
| EV-003 | prompt/docs quote | "`cv_values_` ... Cross-validation values for each alpha (if `store_cv_values=True` and `cv=None`)." | With the flag and `cv=None`, fit must make `cv_values_` available. | Encoded by INT-002 and PO-002. |
| EV-004 | prompt | "Expected ... keeping the cross validation predictions as attribute." | The requested observable is an attribute on the fitted estimator. | Encoded by INT-002 and PO-002. |
| EV-005 | source docs | "This flag is only compatible with `cv=None`" in RidgeCV docs and V1 RidgeClassifierCV docs. | `cv != None` plus the flag remains an error. | Encoded by INT-003 and PO-003. |
| EV-006 | source code | `_BaseRidgeCV.__init__` stores `self.store_cv_values`; `_BaseRidgeCV.fit` forwards it to `_RidgeGCV` and copies `estimator.cv_values_` when true. | Reuse existing storage behavior instead of duplicating classifier-specific logic. | Encoded by PO-002 and F-003. |
| EV-007 | source code | `BaseEstimator._get_param_names` introspects explicit constructor parameters and `get_params` reads attributes of the same names. | The new parameter must appear explicitly and be assigned to an attribute. | Encoded by INT-005 and PO-004. |

## Formal Model

The mini semantics in `fvk/mini-python.k` abstracts only the observable state
needed for this issue:

`rcvcv(StoreFlag, CvIsNone, CvValuesPresent)`

- `StoreFlag` represents `self.store_cv_values`.
- `CvIsNone` represents whether `self.cv is None`.
- `CvValuesPresent` represents whether the fitted public object exposes
  `cv_values_`.

The formal claims in `fvk/ridge-classifier-cv-spec.k` are:

- CLAIM-CONSTRUCT: constructing `RidgeClassifierCV` with any boolean
  `StoreFlag` records that flag and does not produce an unexpected-keyword
  error.
- CLAIM-FIT-STORE: fitting an object with `StoreFlag=True` and `cv=None`
  reaches a state with `CvValuesPresent=True`.
- CLAIM-FIT-NOSTORE: fitting with `StoreFlag=False` does not impose a
  `cv_values_` attribute obligation.
- CLAIM-FIT-INCOMPATIBLE-CV: fitting with `StoreFlag=True` and `cv != None`
  reaches the existing incompatible-CV error state.

## Adequacy Audit

| Formal claim | Public intent coverage | Result |
| --- | --- | --- |
| CLAIM-CONSTRUCT | Matches INT-001 and INT-004. It is not derived from V1 behavior alone; the issue requests the keyword. | Pass |
| CLAIM-FIT-STORE | Matches INT-002 and the quoted `cv_values_` documentation. | Pass |
| CLAIM-FIT-NOSTORE | Matches INT-004 and preserves pre-existing default behavior. | Pass |
| CLAIM-FIT-INCOMPATIBLE-CV | Matches INT-003 and the existing base-class error behavior. | Pass |

No claim over-preserves the legacy bug. The pre-V1 unexpected-keyword behavior
is treated as the symptom, not as a compatibility obligation.

## Public Compatibility Audit

- Changed public symbol: `RidgeClassifierCV.__init__`.
- Signature change: V1 appends `store_cv_values=False` after existing
  `class_weight=None`. Existing positional calls through `class_weight` keep
  their meaning.
- Public callsites found in source/tests use keyword arguments or no positional
  argument beyond existing positions. No callsite requires further source
  changes.
- Subclass/override audit: no in-repo subclass override of
  `RidgeClassifierCV.__init__` was found.
- scikit-learn estimator API: the parameter is explicit in the signature and
  `_BaseRidgeCV.__init__` assigns `self.store_cv_values`, so `get_params` can
  retrieve it.

Compatibility result: pass.
