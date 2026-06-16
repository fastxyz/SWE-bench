# FVK Findings

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## F-1: Legacy finite sentinel violates probability-threshold intent

Classification: code bug, resolved by V1.

Input class: any valid two-class ROC input where `y_score` is a probability
estimate and `max(y_score) > 0`; the clearest boundary case is a sample with
score exactly `1`.

Observed before V1: `thresholds = np.r_[thresholds[0] + 1, thresholds]`
prepended a finite threshold such as `1.8` for max score `0.8`, or `2.0` for
max score `1.0`.

Expected: the first threshold is an artificial no-prediction sentinel, not a
finite probability threshold. All finite thresholds derived from probability
scores remain observed scores in `[0, 1]`.

Evidence: SPEC E1, E2, E3. Proof obligations: PO-3, PO-4.

Resolution: V1 uses `np.inf`, represented formally by `Inf`.

## F-2: Exact public threshold expectations using `2.0` are SUSPECT legacy evidence

Classification: test/documentation compatibility finding, not a production-code
bug in V1.

Input class: public in-repo tests that expected threshold arrays beginning with
`2.0` for `y_score` whose maximum is `1.0`.

Observed in public tests: `assert_array_almost_equal(thresholds, [2.0, ...])`.

Expected under the intent ledger: those exact expectations should move to
`np.inf` if the tests are updated, because the issue identifies the finite
`+ 1` sentinel as the problem.

Evidence: SPEC E6. Proof obligations: PO-6.

Resolution: no test files were modified, per task constraints. The source
docstring and user-guide example were updated in V1 because they are public
documentation, not fixed test files.

## F-3: Clipping the first threshold to 1 is not semantically adequate

Classification: rejected alternative.

Input class: probability estimates where at least one observed score is exactly
`1`.

Observed with the clipping alternative: a prepended threshold of `1` would make
the predicate `score >= threshold` true for samples with score `1`, so the
first ROC point would not represent "no instances predicted".

Expected: the artificial first threshold must select no finite score.

Evidence: SPEC E3 and E5. Proof obligations: PO-3 and PO-5.

Resolution: V1 keeps `np.inf` rather than clipping to 1.

## F-4: Formal proof scope is narrower than the full Python implementation

Classification: proof capability and coverage gap.

Input class: behavior depending on NumPy allocation/dtype details, full
floating-point semantics, `_binary_clf_curve` sorting and cumulative sums,
`drop_intermediate`, warnings when only one class is present, or termination.

Observed in the FVK model: the model proves the sentinel prepend contract over
an abstract list of finite observed thresholds and an `Inf` sentinel.

Expected for a full-library proof: a real Python/NumPy semantics or a much
larger mini-Python/NumPy model would discharge those producer and compatibility
details.

Evidence: SPEC A4. Proof obligations: PO-7.

Resolution: not a reason to change V1. It is a reason to keep tests and to
label the proof constructed, not machine-checked.

## F-5: No additional source edit is justified after the audit

Classification: confirmation finding.

Input class: the sentinel behavior changed by V1.

Observed in V1: `thresholds = np.r_[np.inf, thresholds]`, with docs/examples
updated to show `inf`.

Expected: an explicit no-prediction sentinel and no fabricated finite
probability threshold above 1.

Evidence: SPEC C1-C5 and compatibility audit CA1-CA5. Proof obligations:
PO-1 through PO-6.

Resolution: V1 stands unchanged in the FVK pass.

## Proof-Derived Findings

PF-1. The proof requires the public contract to distinguish finite observed
thresholds from the artificial first threshold. This is not an extra code
precondition; it is the semantic distinction that resolves F-1.

PF-2. The proof cannot justify deleting or weakening tests until the emitted K
commands are actually run and return `#Top`. Test changes remain
recommendation-only.
