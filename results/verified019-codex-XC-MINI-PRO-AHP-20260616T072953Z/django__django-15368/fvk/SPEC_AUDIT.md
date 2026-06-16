# Spec Audit

Adequacy gate status: passed for the scoped `bulk_update()` expression-classification obligation.

| Formal statement | Intent source | Audit result | Notes |
| --- | --- | --- | --- |
| `Resolvable(FRef(NAME)) => Column(NAME)` | E1, E2, E3, E4 | Pass | This is the reported bug and desired behavior. It does not derive expected behavior from V1 alone. |
| `Plain(V) => Param(V)` | E4, E5, E7 | Pass | The public issue asks to fix expression handling, and the existing literal path remains intended frame behavior. |
| `Resolvable(ExprNode(SQL)) => ExprNode(SQL)` | E4, E5, E6 | Pass | The public hint says to use `resolve_expression` generally. This is broader than `F()` but matches local ORM protocol. |
| Batch/field/object loop pointwise invariants | E2, E7 | Pass | The loops are contributors to the observable SQL shape. V1 changes only the value-normalization predicate inside the object loop. |
| Public API unchanged | E7, E8 | Pass | No signature, return type, dispatch, or external call shape changed. |

No formal statement rests on the pre-fix SQL shown in the issue as desired behavior. That display is treated as a SUSPECT legacy symptom under the FVK intent-evidence rule.
