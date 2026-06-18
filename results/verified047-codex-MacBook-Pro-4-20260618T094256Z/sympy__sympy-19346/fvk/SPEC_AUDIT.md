# Spec Audit

Status: constructed, not machine-checked.

| Formal obligation | Intent comparison | Result |
|---|---|---|
| List and tuple claims preserve recursive element output. | Directly matches the issue's examples of correct behavior. | Pass |
| Dict and set claims recursively print contents. | Directly matches the issue's report that plain `{x, y}` and `{x: y}` are wrong. | Pass |
| Dict claim prints both key and value recursively. | The prompt says "elements in dict"; for a mapping, both sides are observable contents. | Pass |
| Empty set is `set()` and empty dict is `{}`. | Required by Python syntax to distinguish empty set from empty dict and preserve eval-friendly output. | Pass |
| Frozenset delegates to set formatting. | Not explicitly named by the issue, but it is the immutable set counterpart and shares the same recursive-printing risk. | Pass, compatibility extension |
| SymPy `Dict` prints as `Dict({...})`. | Not the prompt's primary case, but required to avoid regressing `srepr`'s eval-friendly SymPy object contract. | Pass, regression frame |
| Set/dict member order uses abstract `default_sort_key`. | Exact order is not specified by the issue; existing SymPy printers provide compatibility evidence for this convention. | Pass with note: core intent does not depend on order |
| PythonPrinter inherited behavior remains compatible. | Public subclass uses inherited container methods but overrides symbol printing, so recursive calls still render symbols as Python names there. | Pass |

No formal-English obligation is weaker than the public issue. No required behavior is marked fail or ambiguous. The only abstraction note is exact `default_sort_key` semantics, which is not needed to establish the reported recursive-printing fix.
