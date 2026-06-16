# Iteration Guidance

Status: V1 stands unchanged.

## Decision

Do not edit the source further in this FVK pass. The audit found that V1
matches the intent spec and discharges the representation proof obligations:
classifier scorer targets are decoded, base/regression targets are unchanged,
and the loss path remains internal.

## If Continuing Development

1. Add a regression test for `HistGradientBoostingClassifier` with string
   labels and scorer-based early stopping. A minimal case is the issue
   reproducer with `n_iter_no_change` set and `scoring` left as default.

2. Also test `validation_fraction=None` with string labels, because that path
   uses only the training scorer and is covered by PO-S3.

3. Keep existing early-stopping tests. The constructed proof does not cover
   training integration details, convergence, warm-start interactions, or
   score values.

4. Run the listed `kompile`, `kast`, and `kprove` commands in an environment
   with K installed before treating the proof as machine-verified.

## No-Code-Change Justification

- F1 and PO-C1/PO-S1/PO-S2 confirm the original bug is fixed.
- F2 and PO-S3 confirm no scorer callsite was missed.
- F3 and PO-B1/PO-L1 confirm regression and loss behavior are preserved.
- C1-C3 in `PUBLIC_COMPATIBILITY_AUDIT.md` confirm the private helper does not
  create a public compatibility issue.
