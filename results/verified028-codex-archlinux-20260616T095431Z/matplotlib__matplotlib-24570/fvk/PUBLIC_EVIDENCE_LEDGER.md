# Public Evidence Ledger

## E-001

Source: prompt / issue summary

Quoted evidence: "`align` in `HPacker` is reversed" and "For the `align`
parameter in `HPacker`, the options `top` and `bottom` seems reversed".

Semantic obligation: `HPacker` must give `top` and `bottom` their usual vertical
edge meanings, not the legacy inverted branch table.

Status: encoded by I-001, I-002, PO-002, PO-003, CLAIM-bottom-edge, and
CLAIM-top-edge.

## E-002

Source: prompt reproduction

Quoted evidence: the reproduction sets `align = "bottom"` for an `HPacker` with
children of different heights and shows the current display as the actual
buggy outcome and a bottom-aligned display as expected.

Semantic obligation: a shorter child in an `HPacker(align="bottom")` must not be
moved upward to match top edges; it must keep its bottom edge on the packer's
bottom edge.

Status: encoded by I-001 and PO-002.

## E-003

Source: public hints

Quoted evidence: "For reference, the `VPacker`'s `align='left'` or
`align='right'` does work in the expected manner."

Semantic obligation: the fix should preserve the left/right behavior used by
`VPacker`.

Status: encoded by I-003 and PO-004.

## E-004

Source: public hints

Quoted evidence: "During the call it was also suggested ... that this should
just be considered a plain bugfix" and "I guess ... perhaps we just fix it?"

Semantic obligation: a direct branch-table fix is an acceptable interpretation
if it satisfies the documented edge semantics and does not introduce unrelated
API changes.

Status: encoded by I-005 and FINDINGS F-004.

## E-005

Source: source docstring, `repo/lib/matplotlib/offsetbox.py`

Quoted evidence: `_get_aligned_offsets` says it aligns boxes specified by a
`(height, descent)` pair, returns "bottom offsets of the boxes", and its
terminology "assumes a horizontal layout (i.e., vertical alignment), but the
function works equally for a vertical layout."

Semantic obligation: the helper's returned offsets must be interpreted as
bottom/near-edge offsets. Thus `bottom` belongs with `left` on the lower/near
edge branch, and `top` belongs with `right` on the upper/far edge branch.

Status: encoded by PO-001 through PO-004.

## E-006

Source: source audit of public call sites

Quoted evidence: repository call sites found `HPacker` with `baseline` or
`center`, and `VPacker` with `baseline`, `right`, or `center`; no in-repository
public call site uses `HPacker(align="top")`, `HPacker(align="bottom")`, or
`VPacker(align="top"/"bottom")`.

Semantic obligation: no source call site requires a signature or caller update.
External users relying on the inverted `HPacker` behavior are affected by the
intended bugfix, as acknowledged by the public hints.

Status: encoded by PUBLIC_COMPATIBILITY_AUDIT.md.
