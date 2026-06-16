# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Capture boolean dtype before numeric conversion

Requirement: for both public call forms, `contour(Z, ...)` and
`contour(X, Y, Z, ...)`, the implementation must inspect the original `Z` dtype
before converting it to `float64`.

Code evidence: `repo/lib/matplotlib/contour.py:1457-1459` and
`repo/lib/matplotlib/contour.py:1487-1489` call `ma.asarray(...)`, record
`z.dtype.type is np.bool_`, then convert to `float64`.

Findings: F-001.

Status: discharged by source inspection.

## PO-2: Boolean line contour default is `[0.5]`

Requirement: if `Z` is bool, `filled` is false, no levels were supplied,
`locator` is `None`, and the contour is not log-scale, the selected levels are
`[0.5]`.

Formal claim: C1 in `fvk/SPEC.md` and the first claim in
`fvk/contour-levels-spec.k`.

Code evidence: `repo/lib/matplotlib/contour.py:1125-1131` selects
`levels_arg = [.5]` when the boolean default guard holds and `self.filled` is
false.

Findings: F-001.

Status: discharged by source inspection and constructed K claim.

## PO-3: Boolean filled contour default is `[0, 0.5, 1]`

Requirement: if `Z` is bool, `filled` is true, no levels were supplied,
`locator` is `None`, and the contour is not log-scale, the selected levels are
`[0, 0.5, 1]`.

Formal claim: C2 in `fvk/SPEC.md` and the second claim in
`fvk/contour-levels-spec.k`.

Code evidence: `repo/lib/matplotlib/contour.py:1125-1131` selects
`levels_arg = [0, .5, 1]` when the boolean default guard holds and
`self.filled` is true.  The later filled-contour check at
`repo/lib/matplotlib/contour.py:1151-1152` accepts this three-element list.

Findings: F-002.

Status: discharged by source inspection and constructed K claim.

## PO-4: Boolean line default bypasses the no-inside-level fallback

Requirement: line contours using the boolean default must not be rewritten to
`[zmin]` by the existing inside-range fallback, even when the boolean field is
all false or all true.

Formal claim: C1 is quantified over `HAS`, the abstraction of whether the
selected line level is inside the data range.

Code evidence: `auto_bool_levels` is set at
`repo/lib/matplotlib/contour.py:1131`; the fallback at
`repo/lib/matplotlib/contour.py:1143-1149` runs only when
`not self.filled and not auto_bool_levels`.

Findings: F-003.

Status: discharged by source inspection and constructed K claim.

## PO-5: Caller-directed and non-default paths preserve existing behavior

Requirement: explicit levels, integer level counts, keyword `levels`,
explicit locators, log-scale contouring, and non-bool `Z` arrays must not be
forced to the boolean defaults.

Formal claims: C3 and C4 in `fvk/SPEC.md`; third and fourth claims in
`fvk/contour-levels-spec.k`.

Code evidence: `repo/lib/matplotlib/contour.py:1126-1139` uses positional
`args[0]`, keyword `self.levels`, or `_autolev(...)` unless the boolean default
guard holds.  The guard requires `self._contour_z_is_bool`,
`self.locator is None`, and `not self.logscale`.

Findings: F-004.

Status: discharged by source inspection and constructed K claim.

## PO-6: Numeric binary arrays are not treated as boolean arrays

Requirement: arrays with numeric dtype and values `0`/`1` keep the existing
numeric automatic behavior.

Code evidence: the guard uses `z.dtype.type is np.bool_` before conversion at
`repo/lib/matplotlib/contour.py:1457-1459` and
`repo/lib/matplotlib/contour.py:1487-1489`, so numeric dtypes do not set the
boolean flag.

Findings: F-004.

Status: discharged by source inspection.

## PO-7: Public docstring documents the new default

Requirement: the public `levels` documentation should describe the bool
default behavior.

Code evidence: `repo/lib/matplotlib/contour.py:1592-1594` now documents
`[0.5]` for `.contour` and `[0, 0.5, 1]` for `.contourf`.

Findings: F-005.

Status: discharged by V2 docstring edit.

## PO-8: No forbidden execution or test edits

Requirement: do not run tests, Python, or K tooling; do not modify test files.

Code evidence: only `repo/lib/matplotlib/contour.py` was changed under `repo/`;
FVK and report artifacts were added outside the test suite.

Findings: F-007.

Status: discharged by process audit.  This obligation is not a machine proof.

## PO-9: Scope remains regular 2D-array contouring

Requirement: this fix targets the regular `contour`/`contourf` path for 2D
boolean arrays and does not need to change triangular contour APIs.

Code evidence: `Axes.contour` and `Axes.contourf` construct
`mcontour.QuadContourSet`; triangular contours use `TriContourSet` through
separate `tricontour`/`tricontourf` APIs.

Findings: F-006.

Status: discharged by public-intent scope audit.

## Constructed K Commands

These commands are recorded for later machine checking.  They were not run.

```sh
cd fvk
kompile mini-contour-levels.k --backend haskell
kast --backend haskell contour-levels-spec.k
kprove contour-levels-spec.k
```
