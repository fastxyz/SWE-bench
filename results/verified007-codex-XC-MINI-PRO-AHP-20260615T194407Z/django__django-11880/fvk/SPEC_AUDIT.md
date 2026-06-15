# Spec Audit

| Formal obligation | Intent entry | Result | Notes |
| --- | --- | --- | --- |
| Copied field receives a distinct error_messages object id. | I1, E1, E2 | Pass | This is the reported defect and the central postcondition. |
| Copied error_messages preserves the source payload. | I3 | Pass | The fix isolates state without rebuilding defaults or dropping runtime customizations. |
| Deep-copy strength rather than shallow dictionary copy. | I2, E3 | Pass | The source code uses `copy.deepcopy(self.error_messages, memo)`, not `dict.copy()`. |
| Form construction is covered through `copy.deepcopy(base_fields)`. | I4, E4, E5 | Pass | Field-level contract composes with the form instance copy site. |
| Existing widget and validators behavior is preserved. | I5, E6 | Pass | V1 adds an error_messages copy without changing the surrounding assignments. |
| Public method signature remains unchanged. | I5 | Pass | No callsite or override compatibility issue identified. |

No formal obligation is candidate-derived without public intent support. No
required behavior is marked fail or ambiguous.
