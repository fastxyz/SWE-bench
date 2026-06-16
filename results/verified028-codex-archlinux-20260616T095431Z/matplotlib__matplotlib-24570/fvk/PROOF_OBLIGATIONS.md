# Proof Obligations

Status: constructed, not machine-checked.

## PO-001: Domain

For each child passed to `_get_aligned_offsets`, assume finite extents with
`0 <= d <= h <= H`, where `H` is either the caller-supplied height or
`max(h for h, d in hd_list)`.

Disposition: discharged by the source structure for the reported `HPacker`
case. `HPacker` handles an empty child list before calling the helper; with
`height is None`, the helper computes `H` as the maximum child height.

## PO-002: Bottom Alignment

For `HPacker(align="bottom")`, prove every child bottom edge equals the packer
bottom edge.

Formula: `o = d`, `ydescent = 0`, so `child_bottom = o - d = 0`.

Disposition: discharged by source line `elif align in ["left", "bottom"]` and
the `offsets = [d for h, d in hd_list]` branch.

## PO-003: Top Alignment

For `HPacker(align="top")`, prove every child top edge equals the packer top
edge.

Formula: `o = H - h + d`, `ydescent = 0`, so
`child_top = o - d + h = H`.

Disposition: discharged by source line `elif align in ["right", "top"]` and
the `offsets = [height - h + d for h, d in hd_list]` branch.

## PO-004: VPacker Left/Right Frame

For `VPacker(align="left")`, prove the near horizontal edge is `0`; for
`VPacker(align="right")`, prove the far horizontal edge is the container width.

Disposition: discharged because `left` remains on the `d` branch and `right`
remains on the `H - h + d` branch.

## PO-005: Unchanged Branches

`baseline`, `center`, accepted alignment strings, public signatures, empty
`HPacker` behavior, padding, spacing, and packing mode must remain unchanged.

Disposition: discharged by diff review: V1 changes only membership of `top` and
`bottom` in the two directional branches.

## PO-006: Formal Adequacy

The formal claims must express the public intent rather than legacy behavior.

Disposition: discharged by `fvk/SPEC_AUDIT.md`; the claims state bottom-edge and
top-edge equality and do not preserve the legacy inverted `HPacker` outcome.

## PO-007: Machine Check

The K artifacts must be machine-checkable later, but this session must not run
K tooling.

Disposition: commands are recorded in `fvk/PROOF.md`; they were not executed.
