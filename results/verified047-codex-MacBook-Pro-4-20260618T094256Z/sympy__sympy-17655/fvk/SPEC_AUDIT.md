# Spec Audit

Status: constructed, not machine-checked.

| Obligation | Formal claim(s) | Audit result | Notes |
|---|---|---|---|
| Scalar-left point multiplication matches scalar-right scaling. | `POINT-RMUL`, `POINT-RMUL-DIRECT` | Pass | Directly entailed by issue expected behavior and public hint. |
| The two issue expressions give the same result. | `ISSUE-EXAMPLE` | Pass | Covers the 2D expression shape shown in the issue. |
| Existing right-side point scaling remains coordinate-wise. | `pointMul` semantics, `POINT-RMUL-DIRECT` | Pass | Mirrors `Point.__mul__` docstring and implementation. |
| Reflected add/sub direct point behavior is preserved. | `RADD-FRAME`, `RSUB-FRAME`, compatibility audit | Pass | V1's non-`Expr` branches preserve direct delegation; `Expr` branches preserve symbolic construction. |
| Priority does not steal higher-priority multiplication. | `HIGHER-PRIORITY-FRAME` | Pass | V1 priority is above `Expr` and below public matrix/vector-style priorities. |
| Full Python/K machine proof status. | `PROOF.md` commands | Residual | Commands are emitted but not run by instruction; result remains constructed, not machine-checked. |

No audit failure produced a concrete counterexample or unmet proof obligation
that forces a code edit. V1 stands unchanged.
