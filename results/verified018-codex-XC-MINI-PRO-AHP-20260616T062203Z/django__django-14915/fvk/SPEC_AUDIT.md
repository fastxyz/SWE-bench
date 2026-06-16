# Spec Audit

Status: constructed, not machine-checked.

| Formal claim | Intent entry | Audit result | Notes |
| --- | --- | --- | --- |
| C1 hash claim | I1, E1, E4 | pass | The public hint exactly names `hash(self.value)`. |
| C2 primitive equality claim | I2, E3 | pass | Existing list membership behavior is preserved. |
| C3 wrapper equality claim | I2, E3 | pass | Existing `__eq__()` unwraps another `ModelChoiceIteratorValue`. |
| C4 dictionary membership claim | I1, I3, E1, E2, E4, D3 | pass | This is the reported failing operation for an integer-key dictionary. |
| C5 dictionary getitem claim | I3, E2, D3 | pass | The issue performs `self.show_fields[value]` after membership. |
| C6 frame claim | I4, I5, E5, E6 | pass | The source fix adds a method only; no producer/consumer shape changes. |
| C7 unhashable wrapped value domain | D1 | pass | Python dictionaries and sets require hashable keys, so this is a domain boundary rather than a missing behavior. |
| A1 no `__bool__()` change | A1 | pass | No public evidence requires truthiness parity; adding it could alter valid falsey choice values. |
| A2 no primitive replacement | A2, I4 | pass | Replacement would remove `.instance`, which is part of the wrapper's observed purpose. |

No formal-English claim is candidate-derived without public evidence. The only implementation-derived facts are frame facts used to determine where the wrapper is produced and passed.
