# Spec Audit

Status: constructed, not machine-checked.

| Formal-English item | Intent item(s) | Verdict | Notes |
| --- | --- | --- | --- |
| None returns unchanged. | Intent 1 | Pass | Existing behavior is preserved and does not conflict with the issue. |
| Float input uses context conversion. | Intent 3 | Pass | Public tests assert context-sensitive float behavior. |
| Valid non-float input returns converted decimal. | Intent 2 | Pass | Public tests assert integer and string conversion. |
| Invalid syntax raises `ValidationError`. | Intent 4 | Pass | Public tests assert the existing invalid string behavior. |
| Dict/type-error input raises `ValidationError`. | Intent 5 | Pass | This is the central issue requirement. |
| Malformed/value-error input raises `ValidationError`. | Intent 6 | Pass | Supported by base `Field.to_python()` contract and adjacent numeric field behavior. |
| Other exception input remains raw. | Intent 7 | Pass | This is a narrow frame condition, not a public behavior expansion. |

No formal-English claim is candidate-only or legacy-only. The only behavior that contradicts public intent is the pre-V1 raw `TypeError` on dict input; it is recorded as a resolved finding.
