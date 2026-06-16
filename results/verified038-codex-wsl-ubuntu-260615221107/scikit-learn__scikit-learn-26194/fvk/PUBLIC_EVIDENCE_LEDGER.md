# Public Evidence Ledger

Status: constructed, not machine-checked.

E1. Problem statement: "Thresholds can exceed 1 in `roc_curve` while providing
probability estimate." Obligation: avoid fabricated finite probability
thresholds above 1.

E2. Problem statement: "`+ 1` rule does not make sense in the case `y_score`
is a probability estimate." Obligation: replace the finite `max + 1` sentinel
with a representation that is not a finite probability score.

E3. Problem statement: the extra threshold is "to add a point for `fpr=0` and
`tpr=0`." Obligation: keep a first threshold position that selects no samples
on normal finite-score inputs.

E4. `roc_curve` docstring: scores may be probability estimates, confidence
values, or decision-function outputs. Obligation: the sentinel must also work
for unbounded decision scores.

E5. `roc_curve` return docs: rates use predictions with
`score >= thresholds[i]`. Obligation: the first artificial threshold must be
strictly above all finite scores, or have equivalent sentinel semantics.

E6. Public in-repo tests expected `[2.0, ...]` for max score `1.0`.
Obligation: classify as SUSPECT legacy evidence because it encodes the reported
bug.

E7. Public in-repo consistency test recomputes `tpr` with
`y_score >= threshold`. Obligation: preserve comparison semantics.

E8. Implementation: `_binary_clf_curve` returns observed score values;
`roc_curve` manufactures only the extra first threshold. Obligation: localize
the fix to the prepend operation.
