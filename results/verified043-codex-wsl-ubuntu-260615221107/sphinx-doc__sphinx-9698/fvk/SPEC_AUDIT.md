# Spec Audit

Constructed, not machine-checked.

| Formal English item | Intent item | Result | Rationale |
| --- | --- | --- | --- |
| Qualified `property` returns property text without `()` | Intent 1 | PASS | Directly matches the reproduction `Foo.bar` and expected no-parens behavior. |
| Unqualified module property has no `()` | Intent 3 | PASS | Follows the same issue-derived property rule and existing `PyProperty` fallback. |
| Unqualified no-module property has no `()` | Intent 3 | PASS | Same as above. |
| `property` wins over class/static method flags | Intent 2 | PASS | Prevents a callable branch from reintroducing `()` when `:property:` is present. |
| Non-property entries retain callable shape | Intent 4 | PASS | The issue does not ask to alter normal method/classmethod/staticmethod entries. |
| No object-registration claim changed | Intent 5 | PASS | The code change is limited to text returned by `get_index_text()`. |

No formal item is candidate-derived without public support. The one conflicting
public-test expectation is marked SUSPECT in `PUBLIC_EVIDENCE_LEDGER.md` and
`FINDINGS.md`.
