# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "Use Python stdlib html.escape() to in django.utils.html.escape()" | `escape()` must delegate HTML escaping to stdlib `html.escape()`. | Encoded in SPEC O1/O3 and K claim ESCAPE-OBJECT. |
| E2 | prompt | "`django.utils.html.escape()` partially duplicates the Python stdlib function `html.escape()`." | Remove the private duplicate table rather than preserving it. | Encoded in SPEC and FINDING F1. |
| E3 | prompt | "`html.escape()` has been available since Python 3.2" | Using the stdlib helper is available for this Django version target. | Encoded as compatibility evidence. |
| E4 | prompt | "This function is also faster than Django's" | Prefer stdlib helper; performance is motivating evidence, not formally proved here. | Recorded as non-functional motivation. |
| E5 | prompt | "`html.escape()` converts ' to `&#x27` rather than `&#39`... functionally equivalent HTML... backwards incompatible change" | Literal apostrophe entity may change to stdlib `&#x27;`; legacy public tests expecting `&#39;` are SUSPECT. | Encoded in SPEC O4 and FINDING F2. |
| E6 | docstring | "Return the given text with ampersands, quotes and angle brackets encoded for use in HTML." | Escape `&`, quotes, and angle brackets. | Encoded in SPEC O2/O3. |
| E7 | docstring | "Always escape input, even if it's already escaped and marked as such." | Safe input must still be escaped by `escape()`. | Encoded in K claim ESCAPE-SAFE-INPUT. |
| E8 | source/docs | `mark_safe()` docstring says it marks strings safe for HTML output. | `escape()` must continue to return marked-safe output. | Encoded in SPEC O5 and K claims returning `SafeString`. |
| E9 | source/docs | `conditional_escape()` docstring says it does not operate on pre-escaped strings and otherwise uses `escape()`. | Preserve `conditional_escape()` behavior through `escape()`'s return type and `__html__` protocol. | Encoded in SPEC O6 and compatibility audit. |
| E10 | source comment | `urlize()` helper comment: "If input URL is HTML-escaped, unescape it so that it can be safely fed to smart_urlquote." | The helper must understand escaped entities that the module's escaping path can produce. | Encoded in SPEC O7 and FINDING F3. |
| E11 | public tests | Several visible tests assert `&#39;`. | These encode legacy literal output and conflict with E5 after this issue; they are evidence of blast radius, not an oracle. | Marked SUSPECT in FINDING F2; tests were not edited. |
