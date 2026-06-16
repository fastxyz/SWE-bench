# FVK Specification

Status: constructed, not machine-checked.

## Target

The audited unit is `repo/lib/matplotlib/offsetbox.py`:

- `_get_aligned_offsets(hd_list, height, align)`
- `HPacker.get_extent_offsets`, which passes child `(height, ydescent)` pairs to
  the helper for vertical alignment.
- `VPacker.get_extent_offsets`, which passes child `(width, xdescent)` pairs to
  the same helper for horizontal alignment.

There are no loops in the audited branch table. The proof obligations are
pointwise over each child extent in `hd_list`.

## Public Intent Ledger

The standalone ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`; the critical
entries are:

- E-001 and E-002: the issue identifies `HPacker` `top`/`bottom` as reversed and
  shows `align="bottom"` needing bottom-edge alignment.
- E-003: `VPacker` `left`/`right` should keep their expected behavior.
- E-004: a plain bugfix is an acceptable resolution path.
- E-005: `_get_aligned_offsets` returns bottom offsets and works for both
  vertical and horizontal cross-axis layout.
- E-006: public call-site audit found no source call site needing a signature or
  caller update.

## Mathematical Model

For any child extent represented as `(h, d)`:

- `h` is the child size on the cross axis.
- `d` is the child's descent on that axis.
- `H` is the effective container size on that axis.
- `o` is the returned child offset on that axis.
- The child's lower/near edge in parent-relative coordinates is `o - d`.
- The child's upper/far edge in parent-relative coordinates is `o - d + h`.

For `HPacker`, the cross axis is vertical, so lower/near is bottom and upper/far
is top. For `VPacker`, the cross axis is horizontal, so lower/near is left and
upper/far is right.

## Contract

C-001: For `align == "bottom"`, `_get_aligned_offsets` returns `descent = 0`
and per-child offset `o = d`. Therefore each child's bottom edge is
`o - d = 0`, matching the packer's bottom edge.

C-002: For `align == "top"`, `_get_aligned_offsets` returns `descent = 0` and
per-child offset `o = H - h + d`. Therefore each child's top edge is
`o - d + h = H`, matching the packer's top edge.

C-003: For `align == "left"`, `_get_aligned_offsets` returns `descent = 0` and
per-child offset `o = d`. This preserves `VPacker` left alignment.

C-004: For `align == "right"`, `_get_aligned_offsets` returns `descent = 0` and
per-child offset `o = H - h + d`. This preserves `VPacker` right alignment.

C-005: `baseline`, `center`, accepted alignment values, public signatures, and
empty `HPacker` behavior are frame conditions: they are not changed by this fix.

## Formal Core

The K stopgap artifacts are:

- `fvk/mini-python-offsetbox.k`
- `fvk/offsetbox-align-spec.k`

They model the property-carrying branch table and edge formulas. The model is
minimal, but it preserves the exact observable under audit: lower-edge and
upper-edge equality after applying the computed offset.
