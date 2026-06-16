# FVK Specification: ROC Curve Threshold Sentinel

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Target

This audit targets the `roc_curve` post-processing block in
`repo/sklearn/metrics/_ranking.py`, specifically the artificial threshold that
is prepended after `_binary_clf_curve` and optional `drop_intermediate`
selection:

```python
tps = np.r_[0, tps]
fps = np.r_[0, fps]
thresholds = np.r_[np.inf, thresholds]
```

The helper `_binary_clf_curve` and the collinearity-based
`drop_intermediate` selection are treated as producer obligations: after
validation they provide non-empty arrays `fps`, `tps`, and `thresholds` of
matching length, where `thresholds` are observed finite score values in
decreasing order.

## Intent-Only Spec

I1. `roc_curve` accepts target scores that can be probability estimates,
confidence values, or decision-function scores.

I2. For each returned threshold, `fpr[i]` and `tpr[i]` are computed by the
classifier rule `score >= thresholds[i]`.

I3. The first ROC point is artificial and represents "no instances being
predicted" so that the curve has the initial zero-count point before any
observed score threshold is applied.

I4. When the input scores are probability estimates in `[0, 1]`, `roc_curve`
must not fabricate a finite threshold greater than 1. The first threshold may
be a sentinel that is explicitly not an observed probability threshold.

I5. The fix must preserve the shape alignment between `fpr`, `tpr`, and
`thresholds`, and must not change the public `roc_curve` signature or ordinary
input validation behavior.

I6. Existing public examples and exact-threshold tests that encode
`max(y_score) + 1` are SUSPECT legacy evidence when they conflict with I4,
because the issue identifies that finite `+ 1` behavior as the bug.

## Public Evidence Ledger

E1. Source: problem statement. Quote: "Thresholds can exceed 1 in `roc_curve`
while providing probability estimate." Obligation: avoid fabricated finite
probability thresholds above 1. Status: encoded by PO-4.

E2. Source: problem statement. Quote: "`+ 1` rule does not make sense in the
case `y_score` is a probability estimate." Obligation: replace the finite
`max + 1` sentinel with a representation that is not a finite probability
score. Status: encoded by PO-3 and PO-4.

E3. Source: problem statement. Quote: "this is to add a point for `fpr=0` and
`tpr=0`." Obligation: keep a threshold position whose predicate selects no
samples on meaningful two-class ROC inputs. Status: encoded by PO-3.

E4. Source: `roc_curve` docstring. Quote: "Target scores, can either be
probability estimates of the positive class, confidence values, or
non-thresholded measure of decisions." Obligation: the sentinel representation
must also work for unbounded decision scores. Status: encoded by PO-1 and PO-3.

E5. Source: `roc_curve` return documentation. Quote: "`fpr` and `tpr` use
predictions with score >= `thresholds[i]`." Obligation: any first threshold for
the artificial point must be strictly above every finite observed score, or
otherwise be a sentinel with equivalent comparison semantics. Status: encoded
by PO-3 and PO-5.

E6. Source: current public tests in `repo/sklearn/metrics/tests/test_ranking.py`.
Quote: `assert_array_almost_equal(thresholds, [2.0, 1.0, 0.7, 0.0])`.
Obligation: SUSPECT legacy exact output; it demonstrates the old finite
sentinel and cannot veto E1-E3. Status: FINDING F-2.

E7. Source: current public tests in `repo/sklearn/metrics/tests/test_ranking.py`.
Quote: "Test whether the returned threshold matches up with tpr" followed by
computing `tp = np.sum((y_score >= t) & y_true)`. Obligation: preserve the
threshold comparison semantics. Status: encoded by PO-3.

E8. Source: implementation. `_binary_clf_curve` returns observed score values
only; `roc_curve` alone manufactures the extra first threshold. Obligation:
the repair is localized to the prepend operation. Status: encoded by PO-2.

## Formal Model

The formal core is in:

- `fvk/mini-roc.k`
- `fvk/roc-curve-spec.k`

The model abstracts each finite score as `finite(Int)` and the artificial
sentinel as `Inf`. The `Int` abstraction is deliberately only about boundedness
and comparison: it distinguishes the issue-relevant cases "finite probability
threshold within `[0, 1]`", "finite threshold above 1", and "non-finite
sentinel". It does not model floating-point representation, sorting, or NumPy
array allocation.

## Claims

C1. `prependStart(TS)` rewrites to `Inf ; TS`.

C2. If all observed thresholds in `TS` are finite probability scores in
`[0, 1]`, then all finite thresholds in `Inf ; TS` remain in `[0, 1]`.

C3. `Inf` is a valid no-prediction first threshold because it is strictly above
every finite score in the model.

C4. The legacy `max + 1` path has a concrete counterexample: when the max
observed probability score is `1`, it prepends `finite(2)`, a finite threshold
above 1.

C5. The clipping alternative has a concrete counterexample: if an observed
score is exactly `1`, prepending `finite(1)` does not select no samples under
the `score >= threshold` rule.

## Adequacy Audit

A1. C1-C3 match I2-I5: the formal English says "prepend an explicit sentinel,
preserve finite observed probability thresholds, and make the first threshold
select no finite score."

A2. C4 matches E1-E2 and confirms the reported defect in the old line. It is
not a specification of desired behavior.

A3. C5 matches the issue's proposed workaround discussion and justifies
rejecting clipping as the final fix.

A4. The model does not prove full `_binary_clf_curve`, sorting,
`drop_intermediate`, warning behavior for one-class `y_true`, NumPy dtype
details, or termination. Those are residual proof-scope limits, not blockers
for the sentinel fix because the changed line only consumes the helper output
and prepends one value.

## Compatibility Audit

CA1. Public function signature: unchanged.

CA2. Return shape: preserved because one element is prepended to each of
`fps`, `tps`, and `thresholds`.

CA3. Threshold comparison semantics: preserved for the artificial first point
because `score >= np.inf` is false for every finite validated input score.

CA4. Public tests that only assert no NaN thresholds remain compatible with
`np.inf`; exact tests expecting `[2.0, ...]` are SUSPECT legacy tests under E6.

CA5. Documentation examples were updated so the public displayed output matches
the new sentinel contract.
