# Formal Spec, In English

Status: constructed, not machine-checked.

CLAIM-bottom-edge: For all integer model values satisfying
`0 <= d <= h <= H`, evaluating the modeled bottom branch and then computing the
child lower edge yields `0`. In layout terms, bottom-aligned children share the
parent bottom edge.

CLAIM-top-edge: For all integer model values satisfying `0 <= d <= h <= H`,
evaluating the modeled top branch and then computing the child upper edge yields
`H`. In layout terms, top-aligned children share the parent top edge.

CLAIM-left-edge: For all integer model values satisfying `0 <= d <= w <= W`,
evaluating the modeled left branch and then computing the child near edge yields
`0`. This is the horizontal analogue used by `VPacker(align="left")`.

CLAIM-right-edge: For all integer model values satisfying `0 <= d <= w <= W`,
evaluating the modeled right branch and then computing the child far edge yields
`W`. This is the horizontal analogue used by `VPacker(align="right")`.

CLAIM-baseline-frame: The modeled baseline branch returns `0`, matching the
unchanged source branch.

CLAIM-center-frame: The modeled center branch records the source formula
`(H - h) / 2 + d` as a frame condition. It is not used to justify the
top/bottom fix because Python uses floating-point arithmetic there and the FVK
integer fragment is only a branch-table abstraction.

No loop circularity is required for this unit.
