# Proof Obligations

Status: constructed, not machine-checked.

## PO1: Active estimator definition

Define `active(self.estimators)` as the original `(name, estimator)` sequence
with entries whose estimator is `None` removed, preserving order.

Discharge: V2 constructs `non_none_estimators = [(name, est) ... if est is not
None]` once. This is the source-level representation of `active(ES)`.

Findings: F1, F2.

## PO2: Weighted support check skips dropped estimators

When `sample_weight is not None`, `has_fit_parameter(step, "sample_weight")`
must be called for every active estimator and for no dropped estimator.

Discharge: V2 iterates `for name, step in non_none_estimators`.

Findings: F1.

## PO3: Weighted fit forwards sample_weight to active estimators

If `sample_weight is not None` and all active estimators support it, each active
clone is fitted with `sample_weight=sample_weight`.

Discharge: `_parallel_fit_estimator` passes the keyword when its
`sample_weight` parameter is not `None`; `Parallel` is fed only
`non_none_estimators`.

Findings: F1.

## PO4: Active unsupported estimator still errors

If an active estimator lacks a `sample_weight` fit parameter and
`sample_weight` is supplied, the existing unsupported-estimator `ValueError`
must still be raised naming that active estimator.

Discharge: the existing `ValueError` branch remains unchanged, but now iterates
over `non_none_estimators`.

Findings: none open.

## PO5: All dropped estimators remain invalid

If no active estimators remain, fit must raise the existing all-dropped
`ValueError` under the same valid-name frame.

Discharge: V2 does not alter `n_isnone` or the all-dropped error branch.

Findings: none open.

## PO6: Fitted names align with fitted estimators

For each fitted estimator `self.estimators_[i]`, `named_estimators_` must map
the corresponding active original name to that fitted estimator.

Discharge: V2 zips `non_none_estimators` with `self.estimators_`, so both sides
share the same active-order source.

Findings: F2, F3.

## PO7: Unrelated validation behavior is framed

The fix must not relax invalid-estimator-list checks, weights-length checks, or
name validation.

Discharge: those checks remain present; the only local change is the source of
the support/fitting/naming iteration.

Findings: none open.

## PO8: Honest verification boundary

The FVK proof is constructed only. It must not be reported as machine-checked,
and no tests should be removed without running the emitted K commands.

Discharge: `PROOF.md` and `ITERATION_GUIDANCE.md` label the proof constructed,
not machine-checked, and condition all test-redundancy recommendations.

Findings: F4.
