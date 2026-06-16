# FVK Findings

Status: constructed, not machine-checked. Findings are derived from public
intent, source inspection, and the proof obligations; no tests or code were run.

## F-001 - Resolved code bug: class parameter in `clone`

Input: an estimator instance whose parameter map contains `param -> EstimatorClass`,
as in `StandardScaler(with_mean=StandardScaler)`.

V0 observed behavior from the public issue: recursive `clone(param, safe=False)`
treated `EstimatorClass` as estimator-like because it had `get_params`, then
called `EstimatorClass.get_params(deep=False)` and raised a missing-`self`
`TypeError`.

Expected behavior: no error. The class is a parameter value, not an estimator
instance to recursively clone.

V1/V2 status: resolved by `repo/sklearn/base.py`, guarded by PO-1.

## F-002 - V1 audit gap: composition deep parameter expansion

Input: a public composition parameter manager with a named entry
`(name, EstimatorClass)` and `deep=True`.

V1 observed behavior by source inspection: `_BaseComposition._get_params`
still checked only `hasattr(estimator, 'get_params')`. A class-valued named
entry could therefore call an unbound `EstimatorClass.get_params(deep=True)`.

Expected behavior: include `name -> EstimatorClass` as an ordinary value and do
not emit nested `name__...` parameters for the class.

V2 status: resolved by `repo/sklearn/utils/metaestimators.py`, guarded by PO-4.

## F-003 - Domain decision: direct `clone(EstimatorClass)` with `safe=True`

Input: a class passed directly to `clone` as the top-level object with
`safe=True`.

Observed/expected: the FVK spec keeps the existing non-estimator error path.
The public issue requires support for classes as parameter values inside
estimator instances; it does not require treating the class itself as an
estimator instance.

Status: not a code bug under this spec, guarded by PO-5. If maintainers want
`clone(EstimatorClass)` itself to return the class, that is a separate API
decision.

## F-004 - Verification caveat

The K proof is constructed but not machine-checked because the task forbids
running K tooling. Test removal is therefore not recommended. The emitted
commands in `SPEC.md` and `PROOF.md` are the reproduction path for a later
machine check.
