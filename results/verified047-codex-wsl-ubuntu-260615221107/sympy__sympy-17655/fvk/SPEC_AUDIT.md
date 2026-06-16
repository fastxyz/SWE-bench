# Spec Audit

Status: pass. The formal-English claims match the public intent and do not rely
on hidden tests, upstream patches, or evaluator output.

| Formal claim | Intent entries | Audit |
|---|---|---|
| CLAIM-POINT-RMUL | I1, I2, E1, E3, E4, E5 | Pass: directly states scalar-left point multiplication mirrors existing point scaling. |
| CLAIM-POINT-MUL | I2, I4, E2, E5 | Pass: preserves the existing right-multiplication behavior used as the reference. |
| CLAIM-LEFT-RIGHT-EQUIV | I1, E3 | Pass: exactly matches "both lines give the same result." |
| CLAIM-ADD-COMPOSITION | I3, E2, E3 | Pass: covers the reported composed expression rather than only the raw multiplication. |
| CLAIM-EXPR-ADD-FRAME | I6, F3, E7 | Pass: this is a compatibility frame required by the priority change, not a new intent. |
| CLAIM-EXPR-SUB-FRAME | I6, F3, E7 | Pass: same reflected-dispatch compatibility frame. |
| CLAIM-EXPR-DIV-FRAME | I6, F3, E7 | Pass: same reflected-dispatch compatibility frame. |
| CLAIM-PRIORITY-FRAME | I6, E6 | Pass: priority is justified only as a dispatch mechanism for ordinary SymPy scalars and compatibility with higher-priority systems. |

No claim preserves the pre-fix `Mul(Scalar, Point)` behavior. That behavior is
SUSPECT legacy behavior because the issue identifies it as the path that leads
to the exception.
