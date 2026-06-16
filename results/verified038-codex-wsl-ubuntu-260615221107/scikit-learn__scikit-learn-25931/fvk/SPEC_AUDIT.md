# Spec Audit

Status: constructed, not machine-checked.

| Formal claim | Intent coverage | Audit result | Notes |
| --- | --- | --- | --- |
| C-FIT-NON-AUTO-NO-WARNING | I-001, I-002, I-003 | Pass | Directly covers the reported bug for DataFrame input with fixed contamination. |
| C-FIT-NON-AUTO-OFFSET-FRAME | I-003, I-006 | Pass | Preserves the offset scoring input and percentile shape while removing public revalidation. |
| C-PUBLIC-SCORE-ARRAY-AFTER-NAMES-WARNS | I-004, I-005 | Pass | Confirms the fix does not globally suppress feature-name warnings. |
| C-PUBLIC-SCORE-DATAFRAME-AFTER-NAMES-NO-WARN | I-004, I-006 | Pass | Confirms public scoring with valid names still validates and scores normally. |
| C-FIT-AUTO-UNCHANGED | I-007 | Pass | The auto-contamination branch remains outside the problematic scoring path. |
| C-SPARSE-FIT-SCORES-CSR | I-008 | Pass | Covers the V1 sparse conversion added to preserve scoring expectations after bypassing public validation. |
| C-PRIVATE-SCORE-NO-VALIDATION-WARNING | I-003, I-005 | Pass | The private helper intentionally omits user-input validation and therefore cannot emit the reported warning. |

## Adequacy conclusion

The formal claims match the public intent for the changed behavior. The claims
are neither weaker than the issue because they cover the non-auto DataFrame
`fit` path, nor stronger than public intent because public `score_samples`
warning behavior remains a separate preserved claim.

The model abstracts tree scoring and percentile arithmetic. That abstraction is
adequate for this issue because the public defect is the validation warning
emitted on the wrong control-flow path, not the numerical value of the
IsolationForest score. The offset frame claim still records that the same
validated training representation is scored.
