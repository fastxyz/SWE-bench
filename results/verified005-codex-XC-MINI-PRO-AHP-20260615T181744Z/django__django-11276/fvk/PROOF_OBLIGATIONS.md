# Proof Obligations

Status: constructed, not machine-checked.

| ID | Obligation | Evidence | Disposition |
| --- | --- | --- | --- |
| PO1 | Public intent must require stdlib `html.escape()` rather than preserving Django's `_html_escapes` table. | E1, E2, E3 | Discharged: V1 imports stdlib `html.escape` as `_html_escape` and removes `_html_escapes`. |
| PO2 | `escape()` must coerce input with `str()` before escaping. | Existing wrapper behavior, E6, I2 | Discharged: V1 calls `_html_escape(str(text))`. |
| PO3 | `escape()` must return safe output. | E8, I2 | Discharged: V1 keeps `mark_safe(...)` around the escaped string. |
| PO4 | `escape()` must always escape safe input rather than honoring `__html__()`. | E7 | Discharged: `escape()` still directly calls `str(text)` and does not branch on safe input. |
| PO5 | Apostrophe output must use the stdlib literal spelling. | E5 | Discharged: stdlib `html.escape()` is called with default `quote=True`; the K claim records `"' -> &#x27;"`. |
| PO6 | Existing `conditional_escape()` behavior must remain compatible. | E9, I5 | Discharged by frame: function body unchanged and `escape()` still returns safe output for non-`__html__` values. |
| PO7 | Public API shape must not change. | I6 | Discharged: name, signature, import path, and return class contract are unchanged. |
| PO8 | `urlize()`'s local URL entity helper must recognize the new apostrophe entity spelling. | E10, I7 | Discharged: V1 adds `.replace('&#x27;', "'")` while keeping `&#39;`. |
| PO9 | Legacy tests asserting `&#39;` must not override the issue intent. | E5, E11 | Discharged as an audit decision: those assertions are SUSPECT legacy evidence, not a source obligation. Tests were not modified. |
| PO10 | The proof must not overclaim full Python, stdlib, or Django verification. | FVK honesty gate | Discharged: artifacts are labeled constructed, not machine-checked, and scope is targeted. |

No proof obligation produced a required V2 source edit beyond V1.
