# Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| I-001 | `benchmark/PROBLEM.md` | "Admin doesn't display properly unicode chars in JSONFields." | Form/admin display should preserve readable Unicode for JSONField values. | Encoded by `PO-002`. |
| I-002 | `benchmark/PROBLEM.md` | `json.dumps` defaults cause Chinese to display as `"\u4e2d\u56fd"`. | Legacy escaped display is the reported bug and is SUSPECT as an expected behavior. | Recorded as `F-001`. |
| I-003 | `benchmark/PROBLEM.md` | "this function is only used in Django admin's display" and does not influence MySQL writing/reading. | Keep database serialization unchanged. | Encoded by `PO-005`. |
| I-004 | `benchmark/PROBLEM.md` | Mentions emoji, Chinese, Japanese, and other non-ASCII characters. | Specify the family of non-ASCII JSON text values, not only one example. | Encoded by `PO-002`; concrete discriminator in K uses the Chinese example. |
| I-005 | Source code | `InvalidJSONInput` branch in `prepare_value()`. | Preserve invalid JSON redisplay without dumping. | Encoded by `PO-001`. |
| I-006 | Source code | `encoder` stored on form field and passed from model `formfield()`. | Preserve custom encoder dispatch. | Encoded by `PO-004`. |
| I-007 | Source code | `BoundField.value()`, `Widget.format_value()`, and `textarea.html` render path. | Do not bypass template escaping or form widget rendering. | Encoded by `PO-006`. |
