# Spec Audit

Status: adequacy gate for the constructed, not machine-checked, K claims.

| Formal claim | Intent entries | Verdict | Notes |
|---|---|---|---|
| MASK-NONE-HANDLE | L8 | pass | Matches documented `handle_mask=None` behavior. |
| MASK-BOTH-ABSENT | L3, L7 | pass | Covers no-mask collapse/absent-operand abstraction. |
| MASK-BOTH-NONE | L3, L7 | pass | Covers binary no-mask/no-mask behavior. |
| MASK-RIGHT-ONLY | L2, L7 | pass | Existing asymmetric direction is retained as required. |
| MASK-LEFT-ONLY-ABSENT-OPERAND | L2, L7 | pass | Covers absent right operand with present left mask. |
| MASK-LEFT-ONLY-MASKLESS-OPERAND | L1, L2, L5, L7 | pass | This is the bug-reported branch fixed by V1. |
| MASK-BOTH-PRESENT | L4, L7 | pass | Delegation only occurs when both masks are present. |
| BINARY-SCALAR-MASKLESS-RIGHT | L1, L2, L7 | pass | Models `multiply(1., handle_mask=np.bitwise_or)` wrapping a scalar as a maskless operand. |

## Adequacy conclusion

The formal claims match the public intent without adding candidate-derived
requirements. No ordered result, dtype coercion, or legacy behavior is used to
justify the V1 fix. The formal model is intentionally narrower than full
Astropy arithmetic, but it retains the complete observable needed for this
issue: whether a mask is absent, present and copied, or passed to the callable.
