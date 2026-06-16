# Public Compatibility Audit

Status: constructed by source inspection only.

## Changed Symbol

`repo/sympy/core/mod.py`: `Mod.eval(cls, p, q)`

## Compatibility Checks

| Check | Result |
| --- | --- |
| Public class name `Mod` | Unchanged. |
| Constructor usage `Mod(p, q)` | Unchanged. |
| `eval` signature | Unchanged: `eval(cls, p, q)`. |
| Return protocol | Unchanged: returns `None`, an evaluated expression, or symbolic `Mod` expression through existing paths. |
| Virtual dispatch shape | Unchanged. No new `_eval_Mod` call arguments. |
| Imported public API | Adds local import of `PolynomialError`; no public export or signature change. |
| Exception behavior outside scoped block | Preserved for zero divisor and earlier direct evaluation paths. |

Conclusion: no public caller, subclass override, or producer/consumer protocol
needs an accompanying source change.

