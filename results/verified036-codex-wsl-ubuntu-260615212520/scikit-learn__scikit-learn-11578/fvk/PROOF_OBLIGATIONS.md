# Proof Obligations

Status: constructed, not machine-checked.

## PO-001: Constructor parameter propagation

For every scorer candidate, the temporary estimator must preserve `penalty`,
`dual`, `tol`, `fit_intercept`, `intercept_scaling`, `class_weight`,
`random_state`, `solver`, `max_iter`, `multi_class`, and `verbose` from
`_log_reg_scoring_path`.

Evidence: E2, E3, E4.

Formal claim: `SCORER-PARAMS` in `fvk/log-reg-scoring-spec.k`.

V1 status: discharged by `repo/sklearn/linear_model/logistic.py` lines 925-929.

## PO-002: Per-candidate `C`

For each candidate row, the scorer-visible estimator must have `C` equal to the
current candidate value from `Cs`.

Evidence: E7.

Formal claim: `SCORER-PARAMS` and `SCORE-ALL-CANDIDATES`.

V1 status: discharged by line 950, which assigns `log_reg.C = C` inside the
candidate loop.

## PO-003: Multinomial probability branch

If `_log_reg_scoring_path` is invoked with `multi_class='multinomial'`, any
probability scorer that calls `predict_proba` must observe the softmax branch of
`LogisticRegression.predict_proba`.

Evidence: E1, E5, E6.

Formal claim: `MULTINOMIAL-SOFTMAX`.

V1 status: discharged because `multi_class=multi_class` is passed into the
temporary estimator constructor.

## PO-004: Candidate coefficient/intercept frame

The existing candidate coefficient assignment remains per-candidate and keeps
the current fit-intercept split behavior.

Evidence: implementation shape of the scoring loop and the issue's example,
which assigns the same coefficient row before comparing probability behavior.

Formal claim: `SCORER-PARAMS` and `SCORE-ALL-CANDIDATES`.

V1 status: unchanged from the original implementation except for parameter
propagation and `C`, so this frame condition is preserved.

## PO-005: Compatibility

The fix must not alter public signatures, return shapes, or the scorer callable
protocol.

Evidence: user constraints and `PUBLIC_COMPATIBILITY_AUDIT.md`.

Formal claim: frame condition in `FORMAL_SPEC_ENGLISH.md`.

V1 status: discharged; no signature, return shape, or caller protocol changed.

## PO-006: Verification honesty

The FVK result must be labeled constructed, not machine-checked, because this
session must not run K tooling, tests, or project code.

Evidence: E8 and FVK `verify.md` honesty gate.

V1 status: discharged by artifact labeling and by not executing tests or K.
