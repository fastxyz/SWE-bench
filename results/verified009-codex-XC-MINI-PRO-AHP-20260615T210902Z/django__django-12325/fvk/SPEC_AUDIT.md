# Spec Audit

| Formal claim | Intent entries | Result | Notes |
| --- | --- | --- | --- |
| C1 ordinary field after explicit parent link is ignored | I1, I2 | PASS | Directly matches the issue's failing order. |
| C2 ordinary field before explicit parent link is ignored | I1, I2 | PASS | Matches the issue's working order and proves the ordinary field is irrelevant to the result. |
| C3 standalone ordinary one-to-one field produces no declared parent-link entry | I3, I4 | PASS | This is the behavior V1 only provided for fields with explicit `related_name`; public intent supports all ordinary fields, not only those with `related_name`. |
| C4 non-one-to-one fields are ignored | Source shape and I1 | PASS | This is implementation-shape evidence and does not strengthen public intent. |
| F1 later Django construction steps are outside the mini-model | I4 | PASS WITH BOUNDARY | The model proves the changed contributor. Auto-creation is audited by source reading and proof obligation PO4 rather than encoded in the mini semantics. |

No formal-English claim depends solely on V1 behavior. The V1 condition "ordinary one-to-one fields without a declared reverse name remain parent-link candidates" fails the intent audit because no public issue or docs evidence supports it.
