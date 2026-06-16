# FVK Notes

Status: constructed, not machine-checked. No tests, Python code, or K tooling
were run.

## Decisions

V1 stands unchanged. `fvk/FINDINGS.md` F-001 and F-002 identify the two relevant
defects: multinomial scorer probabilities were routed through an OvR estimator,
and the scorer estimator used constructor defaults for parameters that the path
already knew. `fvk/PROOF_OBLIGATIONS.md` PO-001 and PO-003 are discharged by
the current constructor call in `repo/sklearn/linear_model/logistic.py`, which
passes `multi_class` and the other shared constructor parameters.

The V1 `log_reg.C = C` assignment is retained. F-003 and PO-002 justify it:
although `C` is not a fixed `_log_reg_scoring_path` constructor parameter, each
score is for a specific candidate from `Cs`, so scorer-visible estimator state
should reflect that candidate.

No change was made to `LogisticRegression.__init__` defaults. F-004 rejects that
alternative because V1 now passes `intercept_scaling` explicitly into the
temporary scorer estimator; changing the public constructor default would be
broader than the issue and is not required by PO-001.

No compatibility edit was needed. F-006 and PO-005 show that the helper
signature, return shape, and scorer callable protocol are unchanged.

The proof artifacts deliberately abstract numerical optimization and
floating-point probability arrays. F-005 and PO-006 record that limit, so tests
should be kept until the K commands in `fvk/PROOF.md` can be run and return
`#Top`.
