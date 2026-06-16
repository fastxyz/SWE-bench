# Spec Audit

Status: constructed, not machine-checked.

| Formal item | Intent item(s) | Result | Notes |
| --- | --- | --- | --- |
| 1 | Intent 1, 4; Ledger E1, E3, E4 | Pass | The K selector list models comma-list parsing without preserving legacy boolean collapse. |
| 2 | Intent 2; Ledger E5, E7 | Pass | Bare option compatibility is preserved. |
| 3 | Intent 2; Ledger E7 | Pass | `True` default-option compatibility is preserved. |
| 4 | Intent 5; Ledger E3, E6, E8 | Pass | Named private members can act as explicit member requests. |
| 5 | Intent 5, 7; Ledger E3, E6, E8 | Pass | Merge preserves explicit members and avoids duplicates. |
| 6 | Intent 2, 3, 7; Ledger E2, E5 | Pass | All-members remains all-members, with private selection handled in filtering. |
| 7 | Intent 3; Ledger E2 | Pass | Selected documented private member is kept. |
| 8 | Intent 3; Ledger E2 | Pass | Unselected documented private member is skipped. |
| 9 | Intent 2; Ledger E5 | Pass | Bare `private-members` keeps all eligible private members. |
| 10 | Intent 6; Ledger E9 | Pass | `exclude-members` still wins. |
| 11 | Intent 6; Ledger E9 | Pass | Mock skip still wins. |
| 12 | Intent 5, 7; Ledger E8 | Pass | Existing explicit `members` private-name behavior remains. |
| 13 | Intent 6; existing source attribute behavior | Pass | Source-documented attributes remain documented for filtering. |

No formal-English item is candidate-only or legacy-derived without public evidence. The one V1 adequacy gap was documentation: before this pass the docs described `private-members` as only a flag. That is recorded in `FINDINGS.md` and fixed in `repo/doc/usage/extensions/autodoc.rst`.
