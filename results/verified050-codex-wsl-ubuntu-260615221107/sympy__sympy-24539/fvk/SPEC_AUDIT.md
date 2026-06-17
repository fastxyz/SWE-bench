# Spec Audit

Status: constructed, not machine-checked.

| Formal claim | Intent entries | Audit result | Notes |
|---|---|---|---|
| `POLY-AS-EXPR-DEFAULT` | I-2, E-5 | Pass | The no-symbol fallback to `self.ring.symbols` is public behavior and remains unchanged. |
| `POLY-AS-EXPR-SUPPLIED` | I-1, I-4, E-1, E-2, E-3, E-7 | Pass | The claim states exactly the issue intent: same-arity supplied symbols reach expression construction. |
| `POLY-AS-EXPR-BAD-ARITY` | I-3, E-4 | Pass | The claim preserves wrong-arity rejection without over-specifying the exact message. |
| `FRAC-AS-EXPR-SUPPLIED` | I-6, E-8 | Pass | The claim captures the public forwarding behavior and verifies that the `PolyElement` correction composes with it. |
| Frame condition: signature unchanged | I-5 | Pass | V1 changes only branch assignment order inside the method body. |

No claim is derived solely from candidate behavior. The pre-fix display in the
issue is treated as a SUSPECT legacy behavior and appears only as the negative
side of Finding F-1.
