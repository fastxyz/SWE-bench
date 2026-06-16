# FVK Notes

## Decisions

The V1 behavior change stands.  F-001 and F-002 identify the original bug:
boolean `Z` was converted to numeric data before automatic level selection, so
`contour` and `contourf` could not choose boolean-specific defaults.  PO-1,
PO-2, and PO-3 show that V1 records the original dtype before conversion and
selects `[0.5]` for line contours and `[0, 0.5, 1]` for filled contours.

I kept the V1 `auto_bool_levels` bypass for the line-contour inside-range
fallback.  F-003 makes that an explicit obligation for all-true and all-false
boolean arrays, and PO-4 shows the fallback is skipped only for the boolean
default path.

I kept the V1 exclusions for explicit level inputs, explicit locators, log-scale
contouring, and non-bool numeric arrays.  F-004 explains the caller-directed
behavior to preserve, and PO-5 plus PO-6 show those cases remain on the
existing path.

I added one V2 source edit: the `levels` docstring now documents the boolean
defaults.  F-005 identified the V1 documentation gap, and PO-7 records the
specific source lines that discharge it.

I did not extend the fix to triangular contours.  F-006 records this as a scope
boundary because the public issue describes 2D boolean arrays passed to regular
`contour`/`contourf`, and PO-9 records the corresponding proof obligation.

I did not run tests, Python, or K tooling, and I did not edit test files.  F-007
and PO-8 record that constraint.  The K artifacts and proof are constructed,
not machine-checked.

## Artifacts

The FVK artifact set is under `fvk/`:

- `SPEC.md`
- `FINDINGS.md`
- `PROOF_OBLIGATIONS.md`
- `PROOF.md`
- `ITERATION_GUIDANCE.md`
- `mini-contour-levels.k`
- `contour-levels-spec.k`

The compact K model is intentionally limited to the level-selection branch.  It
does not attempt to model NumPy, contourpy, or rendering; those are outside the
property changed by this fix.
