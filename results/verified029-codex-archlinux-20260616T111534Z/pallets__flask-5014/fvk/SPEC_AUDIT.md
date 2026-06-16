# Spec Adequacy Audit

| Formal claim | Intent obligation | Result | Notes |
| --- | --- | --- | --- |
| `C-INIT-EMPTY` | Empty constructor names raise `ValueError`. | Pass | Directly matches intent item 2. |
| `C-INIT-DOTTED` | Existing dotted constructor-name validation remains. | Pass | Frame condition from public changelog. |
| `C-INIT-NONEMPTY` | Valid non-empty names keep working. | Pass | Frame condition; does not over-specify unrelated fields. |
| `C-REGISTER-EMPTY-OVERRIDE` | Registration `name=""` is an empty effective name and raises `ValueError`. | Pass | Derived from `name=` public behavior and issue intent. |
| `C-REGISTER-EMPTY-DEFAULT` | A stored empty name must not become an effective registration name. | Pass | Defensive coverage for mutation/subclass cases; follows same intent. |
| `C-REGISTER-NONEMPTY-NOCONFLICT` | Non-empty registration names keep existing behavior. | Pass | Frame condition; duplicate conflict behavior is not changed. |

No claim relies on a hidden test, evaluator output, benchmark result, or original upstream fix. No claim preserves a behavior that the public issue identifies as buggy.

