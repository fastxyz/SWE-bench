# Formal Spec English

Status: constructed for FVK audit; not machine-checked.

## Claim 1: constructor-order tuple dash forwarding

For every raw dash offset `O`, positive dash cycle `C`, non-negative linewidth
`LW`, and `lines.scale_dashes` setting `SCALE`, if a visible patch runs the
constructor-order sequence `set_linestyle((O, seq))`, `set_linewidth(LW)`, and
`draw`, the renderer graphics context receives dash offset
`scaleOffset(SCALE, O mod C, LW)`.

This is the path used by the public reproduction, where patch constructors
receive both `linewidth=4` and `ls=(offset, (10, 10))`.

## Claim 2: post-init tuple dash forwarding

For every raw dash offset `O`, positive dash cycle `C`, existing non-negative
linewidth `LW`, and `SCALE`, if a visible patch has its linestyle set to
`(O, seq)` after linewidth is already present and then `draw` is called, the
renderer graphics context receives dash offset
`scaleOffset(SCALE, O mod C, LW)`.

This covers direct calls to `Patch.set_linestyle` after object construction.

## Claim 3: non-zero offset is not zeroed

For every visible patch with positive linewidth and valid dash tuple, if
`O mod C != 0`, then after constructor-order setup and draw, the renderer
dash offset is not zero. In the public example with `O = 10`, `C = 20`,
`LW = 4`, and scaling enabled, the renderer receives `40`, not `0`.

## Claim 4: invisible-patch frame behavior

If a patch is not visible, `draw` returns without calling `set_dashes`. The
dash forwarding fix does not alter the visibility guard.

## Expected result summary

The English meaning of the K claims is that `Patch.draw()` forwards the stored
dash pattern produced by the existing setter/scaling path. It does not reset
the dash offset to zero. This is exactly the issue's required behavioral
change.
