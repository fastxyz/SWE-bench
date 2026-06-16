# Spec Audit

Status: constructed, not machine-checked.

| Formal item | Intent item | Verdict | Notes |
| --- | --- | --- | --- |
| K-001 | I-004 | pass | Empty-value behavior is preserved. |
| K-002 | I-004 | pass | Valid submitted keys still return the matched model instance. |
| K-003 | I-004 | pass | Correct-model instances still resolve by the same lookup key used by the implementation. |
| K-004 | I-001, I-002 | pass | Absent non-empty submitted keys produce `invalid_choice` and carry `params['value']`. |
| K-005 | I-001, I-002 | pass | Correct-model instances outside the queryset expose the lookup key that failed validation. |
| K-006 | I-001, I-002 | pass | Conversion/type failures expose the rejected value. |
| K-007 | I-003 | pass | The default message includes the value placeholder. |
| K-008 | I-005 | pass | No public signature or success return shape changed. |
| Legacy public tests for old default text | I-006 | suspect, not blocking | These tests encode the old behavior named by the issue. They should not veto the spec. |

Adequacy conclusion: the formal claims cover the full intended runtime behavior
space for this issue: empty input, valid lookup, invalid missing lookup,
invalid model-instance lookup, and invalid conversion/type failure.

