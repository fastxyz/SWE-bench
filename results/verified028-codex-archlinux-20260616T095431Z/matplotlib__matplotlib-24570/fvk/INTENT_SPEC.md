# Intent Specification

Status: constructed from public issue text, public hints, docstrings, and source
comments. This is intent-first; candidate behavior is checked later.

## Required Behavior

I-001: `HPacker(align="bottom")` must align the bottom edges of horizontally
packed children. For a child with height `h` and descent `d` inside an effective
container height `H`, the returned bottom offset must make
`offset - d == 0` when the packer's descent is `0`.

I-002: `HPacker(align="top")` must align the top edges of horizontally packed
children. For a child with height `h` and descent `d` inside effective height
`H`, the returned bottom offset must make `offset - d + h == H` when the
packer's descent is `0`.

I-003: The shared helper must keep the established horizontal-axis meanings used
by `VPacker`: `left` aligns the lower/near edge of the cross-axis coordinate and
`right` aligns the upper/far edge.

I-004: `baseline`, `center`, input validation for accepted alignment strings,
padding, packing mode, public signatures, and empty-child behavior are outside
the reported defect and must not be changed.

I-005: The migration alternatives in the public hints are possible process
choices, but the issue discussion also identifies the inversion as a plain bug.
The repair may therefore be a direct bugfix if the branch table satisfies
I-001 through I-004 without broader API churn.

## Domain Assumptions

D-001: The geometric obligations apply to finite child extents returned by
offsetbox children: `0 <= d <= h` and `h <= H`. If `height is None`,
`_get_aligned_offsets` computes `H = max(h for h, d in hd_list)`, so `h <= H`
holds for every listed child.

D-002: `hd_list` is nonempty when `height is None`, matching existing helper
behavior. Empty `HPacker` children are handled before calling the helper.

D-003: This FVK pass proves partial correctness of the alignment formulas. It
does not machine-check full Python or renderer behavior.
