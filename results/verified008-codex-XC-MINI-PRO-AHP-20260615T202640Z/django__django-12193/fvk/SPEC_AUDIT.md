# Spec Audit

Status: constructed, not machine-checked.

| Formal obligation | Intent entry | Verdict | Notes |
| --- | --- | --- | --- |
| `CHECKBOX-CONTEXT-NO-MUTATE` | E3, E4, E5 | Pass | The issue identifies mutation of the attrs argument as the cause. Copying before adding generated `checked` matches the base widget attrs-building pattern. |
| `SPLIT-ARRAY-CHECKED-INDEPENDENT` | E1, E2, E6 | Pass | The formal statement covers the whole observable issue: every subwidget's checked state depends on the original attrs and that entry's value, not prior entries. |
| `REPRODUCTION-FALSE-TRUE-FALSE` | E1, E2 | Pass | This is the concrete counterexample family named by the issue. |
| Explicit `checked` attrs are preserved | Intent item 4, E5 | Pass | The spec allows original `C = true`, so all outputs remain checked by explicit caller request. |
| Public API compatibility | Intent item 5, E7 | Pass | V1 changes no method signature, call shape, return shape, or dispatch target. |

No formal-English obligation is weaker than the issue intent. The only abstraction is attrs shape: the proof models the `checked` key and handles other attrs by source-level frame reasoning rather than by enumerating arbitrary Python dictionary contents.
