# Spec Audit

Status: pass, constructed and not machine-checked.

| Formal Item | Intent Entries | Result | Notes |
| --- | --- | --- | --- |
| `SYMBOLS-FUNCTION-NESTED-RANGES` | I2, I3, I4; evidence E1, E2, E3 | Pass | Matches the issue's concrete expected result and preserves the outer grouping. |
| `SYMBOLS-ITERABLE-PRESERVES-CLASS` | I1, I2; evidence E1, E4, E7 | Pass | Generalizes from `Function` to the documented `cls` mechanism without changing the public API. |
| `STRING-RANGE-USES-CLASS` | I1, I5; evidence E4, E6 | Pass | Restates the existing string/range branch behavior that already used `cls` directly. |
| Frame: output shape unchanged | I4, I5; evidence E3, E5 | Pass | The production change only forwards `cls`; it does not alter `type(names)(result)`. |
| Frame: assumptions/kwargs unchanged | I5 | Pass | The production change passes the same `**args`; the added explicit keyword is only `cls`. |

No formal-English obligation is candidate-derived without public evidence. The
pre-fix `Symbol` result is marked SUSPECT in the evidence ledger because the
problem statement identifies it as the bug.
