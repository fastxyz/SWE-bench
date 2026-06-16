# FVK Findings

Status: constructed, not machine-checked.

## F-001: Resolved code bug, multinomial scoring used OvR probabilities

Input class: `_log_reg_scoring_path(..., scoring='neg_log_loss',
multi_class='multinomial')`.

Observed before V1: the temporary scorer estimator was constructed without
`multi_class`, so `LogisticRegression.predict_proba` selected the default OvR
branch.

Expected: the scorer estimator should have `multi_class='multinomial'`, causing
`predict_proba` to select the softmax branch.

Evidence: ledger E1, E2, E3; proof obligation PO-003.

Status after audit: resolved by V1. No further source edit required.

## F-002: Resolved completeness gap, scorer estimator used other constructor defaults

Input class: `_log_reg_scoring_path` called with non-default constructor
parameters that are also accepted by `LogisticRegression`.

Observed before V1: the scorer estimator inherited only `fit_intercept`; other
parameters such as `penalty`, `dual`, `tol`, `solver`, `max_iter`, and
`verbose` were defaulted on the estimator visible to scoring.

Expected: the scorer estimator should inherit the path parameters listed in the
public hint.

Evidence: ledger E4; proof obligation PO-001.

Status after audit: resolved by V1. The constructor call now passes all shared
parameters available in `_log_reg_scoring_path`.

## F-003: Confirmed V1 extension, current candidate `C` should be visible

Input class: custom scorers that inspect `estimator.C` while
`_log_reg_scoring_path` iterates over multiple candidate `Cs`.

Observed before V1: `LogisticRegression`'s default `C=1.0` would remain visible
for every candidate.

Expected: the scorer-visible estimator should represent the current candidate
being scored.

Evidence: ledger E7; proof obligation PO-002.

Status after audit: V1's `log_reg.C = C` is justified and retained.

## F-004: Rejected alternative, changing `LogisticRegression.__init__` defaults

Alternative considered: change the public `LogisticRegression` constructor
default for `intercept_scaling` from `1` to `1.` as mentioned in the historical
PR text.

Reason rejected: the audited defect is in `_log_reg_scoring_path` constructing
the scorer estimator with defaults. V1 passes the current
`intercept_scaling` value explicitly, so changing the public constructor default
is not needed for PO-001 and would be broader API churn.

Status after audit: no source edit.

## F-005: Proof capability limit, numerical probabilities are abstracted

Input class: assertions about exact softmax values, exact OvR-normalized
values, optimizer convergence, or exact log-loss scores.

Observed in FVK model: those numeric arrays are abstracted away. The model
proves branch and parameter visibility, not floating-point arithmetic.

Expected for future machine verification: either keep numeric behavior covered
by tests, or use a richer Python/Numpy/scikit-learn semantics.

Evidence: proof obligation PO-006 and the scope notes in `SPEC.md`.

Status after audit: not a source bug. Keep public and hidden tests; do not
remove tests based on this constructed proof.

## F-006: Compatibility check passed

Input class: public callers of `_log_reg_scoring_path` and the scorer callable
protocol.

Observed after V1: no signature, return shape, or scorer callable protocol
changed.

Expected: compatibility preserved.

Evidence: `PUBLIC_COMPATIBILITY_AUDIT.md`; proof obligation PO-005.

Status after audit: no source edit.
