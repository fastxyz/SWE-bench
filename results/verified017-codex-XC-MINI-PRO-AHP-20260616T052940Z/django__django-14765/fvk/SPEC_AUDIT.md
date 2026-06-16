# SPEC AUDIT

Status: constructed, not machine-checked.

| Formal obligation | Intent match | Reason |
| --- | --- | --- |
| `PROJECTSTATE-NONE` | pass | Matches intent item 4: `None` remains the empty-set sentinel. |
| `PROJECTSTATE-EMPTY-SET` | pass | Matches intent items 1 and 2: an empty set is non-`None`, so it is asserted as a set and accepted. |
| `PROJECTSTATE-NONEMPTY-SET` | pass | Matches intent items 1 and 2: a provided set is accepted directly. |
| `PROJECTSTATE-NONSET-ASSERTS` | pass | Matches intent items 2 and 3: non-set non-`None` values assert instead of converting. |
| Successful-construction frame | pass | Matches intent item 6: unrelated constructor fields are unchanged. |
| External non-set iterable compatibility | pass | Matches intent item 5 and is explicitly recorded as `F4`, not hidden. |

No formal claim is legacy-derived without public intent support.

