# Spec Audit

Status: constructed, not machine-checked.

| Claim | Intent entries | Audit | Notes |
|---|---:|---|---|
| C1 | I1, I2, E1, E2 | PASS | Directly required by the issue. |
| C2 | I1, I2, E3 | PASS | Public hint explicitly calls out the different-type branch. |
| C3 | I1, I3 | PASS | Required to prevent `!=` from swallowing fallback. |
| C4 | I1, E1, E2 | PASS | Models the delegation behavior cited in the issue. |
| C5 | I1, E5 | PASS | Public issue states this final result for equality. |
| C6 | I4, E4 | PASS | Required by "other rich comparison methods" language. |
| C7 | I8 | PASS | The issue targets unknown operands, not recognized invalid relational math. |
| C8 | I5, I6, E6 | PASS | Numeric overrides otherwise bypass `Basic` and `Expr`. |
| C9 | I6, I7, E7, E8 | PASS | Captures the V2 correction to V1's singleton drift. |
| C10 | I9 | PASS | No signature or test-file changes. |

No claim is marked fail or ambiguous. The proof remains constructed, not machine-checked.
