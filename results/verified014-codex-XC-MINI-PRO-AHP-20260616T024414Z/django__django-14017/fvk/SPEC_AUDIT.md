# Spec Audit

Status: constructed, not machine-checked.

| Formal claim | Intent coverage | Verdict |
| --- | --- | --- |
| `(COMBINE-NONCOND)` | Matches E7 and preserves existing public rejection of plain non-conditional objects. | Pass |
| `(COMBINE-EMPTY-SELF-COND-EXPR)` | Matches E1's concrete `Q() & Exists(...)` reproduction and E5's conditional-expression convention. | Pass |
| `(COMBINE-LOOKUP-SELF-COND-EXPR-AND)` | Matches E2 and E4 for non-empty `Q(...) & Exists(...)`. | Pass |
| `(COMBINE-LOOKUP-SELF-COND-EXPR-OR)` | Matches E2 and E4 for non-empty `Q(...) | Exists(...)`. | Pass |
| `(DECONSTRUCT-EXPR-Q)` | Required by E1 plus the existing empty-`Q` clone path in `Q._combine()`. Without it, `Q() & Exists(...)` would leave the `TypeError` path but fail during clone. | Pass |
| `(DECONSTRUCT-LOOKUP-Q)` | Matches existing `Q.deconstruct()` behavior and public `Q` deconstruction tests. | Pass |

No claim is based solely on V1 behavior. The only implementation-derived facts
used in the spec are control-flow facts needed to model the candidate:
`Q._combine()` wraps accepted non-`Q` operands and clones empty operands through
`deconstruct()`.

