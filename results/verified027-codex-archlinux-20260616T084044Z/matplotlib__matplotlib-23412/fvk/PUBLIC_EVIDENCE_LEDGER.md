# Public Evidence Ledger

Status: constructed for FVK audit; not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt / issue title | "offset dash linestyle has no effect in patch objects" | Patch dash tuple offset is an intended observable input; ignoring it is the reported bug. | Encoded in `PATCH-NONZERO-OFFSET-NOT-ZEROED`. |
| E2 | prompt / reproduction | Rectangle patches use `ls=(0,(10,10))` and `ls=(10,(10,10))`. | The tuple offset must survive for `Rectangle`, a base `Patch.draw()` user. | Encoded in constructor-order claim. |
| E3 | prompt / actual outcome | "the patch edge lines overlap, not adhering to the offset" | The pre-fix behavior of forcing both offsets to the same rendered phase is wrong. | Recorded as finding F-001. |
| E4 | prompt / expected outcome | "expected outcome is shown here with Line2D objects" | Patch dash tuple behavior should match the `Line2D` dash offset convention. | Encoded by using `_get_dash_pattern` and `_scale_dashes` as model obligations. |
| E5 | prompt / additional information | "I have tried the Ellipse patch object as well and found the same issue." | The fix must apply through shared patch drawing, not only a rectangle-specific path. | Encoded by targeting `Patch.draw()`. |
| E6 | public hint | "replacing the 0 here with the passed offset works completely fine" | The suspicious mechanism is draw-time zeroing of the stored dash offset. | Encoded as the V1 source change and finding F-001. |
| E7 | public hint | "I couldn't find a reason why we should ignore dash offset here... To me this is simply a bug" | Prefer supporting offsets over documenting ignored offsets; no warning is required for this niche compatibility break. | Encoded in `INTENT_SPEC.md` item 6 and finding F-003. |
| E8 | source docstring | `Patch.set_linestyle` documents `(offset, onoffseq)`. | Tuple offsets are part of the patch linestyle API contract. | Encoded in the setter and draw-forwarding claims. |
| E9 | source implementation | `_get_dash_pattern` returns `(offset, dashes)` and `_scale_dashes` scales both offset and dashes. | The setter/storage path already preserves offsets; the proof must check whether draw forwards that stored value. | Encoded in `PATCH-TUPLE-DASH-FORWARDED-AFTER-CONSTRUCTOR-ORDER`. |
| E10 | source implementation, legacy | Pre-fix `Patch.draw()` comment: "Patch has traditionally ignored the dashoffset." | SUSPECT legacy behavior: it conflicts with E1-E7 and must not define the spec. | Rejected in `SPEC_AUDIT.md`; resolved by V1. |
