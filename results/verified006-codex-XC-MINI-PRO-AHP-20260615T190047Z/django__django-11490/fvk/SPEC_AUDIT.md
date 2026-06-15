# Spec Audit

Status: adequacy audit, constructed not machine-checked.

| Formal claim | Intent item | Audit | Notes |
| -- | -- | -- | -- |
| C-1 repeated V1 compilations are independent | Intent items 2, 3, 4 | Pass | This is the direct issue obligation from I-001 and I-002. |
| C-2 applies outer fields during a single compilation | Intent item 2 and evidence I-005 | Pass | Preserves the existing set-operation column-compatibility rule. |
| C-3 preserves explicit child selection | Intent item 5 and evidence I-005 | Pass | The existing branch condition is retained on a cloned child. |
| Original child query unchanged | Intent item 4 and evidence I-003/I-004 | Pass | Queryset clone semantics and the bug report support non-mutation. |
| No public API/signature change | Intent item 6 | Pass | V1 changes only internal compiler child query identity. |

No formal claim is marked fail or ambiguous. The only caveat is the honesty
gate: the proof is constructed, not machine-checked.
