# FVK Findings

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## F1: Pre-V1 weighted fit inspected dropped estimators

Input: `VotingClassifier` with `estimators=[("lr", None), ("rf", RF)]` and
`sample_weight` supplied.

Observed in the issue: `AttributeError: 'NoneType' object has no attribute
'fit'`.

Expected: the support check skips `lr`, checks `rf`, and fit proceeds with
only `rf` if it supports `sample_weight`.

Classification: code bug, resolved by V1 and preserved in V2.

Proof link: `FIT-REPORTED-EXAMPLE`, `FIT-SAMPLE-WEIGHT-ACTIVE`; obligations
PO1, PO2, PO3.

## F2: V1 left an avoidable duplicated-filter proof obligation

Input shape: any estimator list with a dropped estimator before an active
estimator, for example `[("lr", None), ("rf", RF)]`.

Observed in V1 source: support checking, fitting, and `named_estimators_`
alignment each used their own filter or generator expression over non-`None`
estimators.

Expected: all three operations should be driven by the same active estimator
sequence to make alignment direct and prevent future divergence.

Classification: proof-maintainability finding, resolved by V2 refactor.

Proof link: obligations PO1 and PO6.

## F3: `named_estimators_` misalignment existed in the baseline

Input shape: `[("lr", LR), ("rf", None), ("nb", NB)]`.

Observed in baseline source: `zip(self.estimators, self.estimators_)` paired
the full configured list with the filtered fitted list, so a name after a
dropped estimator could point to the wrong fitted estimator.

Expected: `named_estimators_` maps active names to their corresponding fitted
estimators only.

Classification: adjacent code bug surfaced by the same filtered/non-filtered
mismatch, resolved by V1 and kept in V2.

Proof link: `FIT-SAMPLE-WEIGHT-ACTIVE`; obligation PO6.

## F4: Formal proof capability boundary

The mini semantics model estimator records, dropped status, sample-weight
support, and fit/name routing. They do not model actual machine-learning
training, numpy array validation, label encoding, or joblib internals.

Classification: proof capability boundary, not a code bug.

Recommended action: keep integration and estimator-behavior tests; only routing
tests matching the formal domain are candidates for conditional redundancy
after a real `kprove` run.

Proof link: obligations PO8 and `PROOF.md` residual-risk section.
