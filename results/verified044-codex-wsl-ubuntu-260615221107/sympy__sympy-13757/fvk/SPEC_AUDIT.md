# Spec Adequacy Audit

Status: constructed, not machine-checked.

| Formal item | Intent entries | Adequacy result | Notes |
| --- | --- | --- | --- |
| `POLY-RMUL-X` | I1, I2, I3; evidence E1, E2, E4-E6 | Pass | It proves the reported `x*Poly(x)` family member on the default multiplication path. |
| `POLY-RMUL-SMINUS2` | I1, I2, I4; evidence E1, E3-E6 | Pass | It proves the reported SymPy integer left operand path. |
| `POLY-RMUL-FALLBACK` | I5; evidence E6 | Pass | It preserves the existing documented-by-code fallback branch when conversion is impossible. |
| `POLY-PRIORITY-ORDINARY-EXPR` | I1; evidence E4, E5 | Pass | The side condition is exactly the mechanism needed by SymPy's dispatch decorator. |
| `POLY-PRIORITY-COMPAT` | I6; evidence E8 | Pass with residual risk | The formal model abstracts the broader class hierarchy, so this is a compatibility obligation rather than a full proof over all SymPy classes. Source inspection found no reason to revise V1. |

No item is supported only by current V1 behavior. The reported pre-fix outputs are treated as symptoms, not expected behavior.
