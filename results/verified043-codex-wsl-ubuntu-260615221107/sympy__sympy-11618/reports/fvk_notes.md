# FVK Notes

## Decision Summary

V1 stands with no additional source edits.

The FVK audit confirmed that the public obligation is the Euclidean
`Point.distance` contract for mixed-dimensional points. The V1 implementation
uses `zip_longest(..., fillvalue=S.Zero)`, which discharges the general
zero-fill obligation in `fvk/PROOF_OBLIGATIONS.md` PO-001 and the reported
example in PO-002. This resolves `fvk/FINDINGS.md` F-001.

## Source Changes

No source files under `repo/` were changed during the FVK pass.

I kept `repo/sympy/geometry/point.py` unchanged because:

- F-001 is already resolved by PO-001 and PO-002: extra coordinates are included
  with zero fill, so `Point(2, 0).distance(Point(1, 0, 2))` computes `sqrt(5)`.
- F-002 is discharged by PO-003: same-dimensional distance behavior is preserved
  because `zip_longest` and `zip` produce the same coordinate pairs when both
  inputs have equal length.
- PO-004 confirms the public signature and return shape did not change.

## Rejected Edits

I considered whether to expand the change to adjacent zip-based methods such as
`midpoint`, `dot`, or `taxicab_distance`. I did not make those edits because
F-003 classifies them as underspecified adjacent behavior, not an obligation for
this issue. The public issue explicitly calls `.distance` and expects the
Euclidean result `sqrt(5)`, so broadening other methods would not trace to a
required proof obligation.

I also did not add or modify tests. The task prohibits modifying test files, and
F-004/PO-005 require the proof to remain "constructed, not machine-checked"
because tests, Python, and K tooling cannot be run here.

## Artifacts Added

I added the required FVK artifacts:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

I also added the formal core required by the FVK method:

- `fvk/mini-python.k`
- `fvk/point-distance-spec.k`

These files encode PO-001 through PO-003 and include the exact `kompile`,
`kast`, and `kprove` commands required by PO-005. The commands were written into
the artifacts but not executed.
