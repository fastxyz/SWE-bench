# FVK Notes

The V1 `repo/sklearn/base.py` changes stand. `fvk/FINDINGS.md` F-001 identifies
the original bug as a class-valued parameter being treated as an estimator
instance because it exposes `get_params`; `fvk/PROOF_OBLIGATIONS.md` PO-1 and
PO-3 trace why the V1 guards in `clone` and `BaseEstimator.get_params` discharge
that issue. PO-2 also justifies keeping the predicate broader than
`BaseEstimator`, preserving non-class `get_params` objects such as kernels.

The FVK audit found one V1 gap and I changed source for it:
`repo/sklearn/utils/metaestimators.py::_BaseComposition._get_params` still used
the loose `hasattr(estimator, 'get_params')` check. F-002 describes the concrete
failure mode for class-valued named entries, and PO-4 requires the same
`not isinstance(..., six.class_types)` guard there. I applied that edit.

I did not change direct `clone(EstimatorClass, safe=True)` behavior. F-003 and
PO-5 classify it as outside the public issue's required support: the issue asks
for estimator classes as parameter values to clone without error, not for a
class itself to be accepted as a top-level estimator instance.

The proof artifacts are constructed, not machine-checked, because this task
forbids running tests, Python, or K tooling. F-004 records that caveat; no tests
were modified or removed.
