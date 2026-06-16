# FVK Proof

Status: constructed, not machine-checked.  No `kompile`, `kast`, `kprove`,
Python, or test commands were run.

## What Is Proved

For regular quadrilateral contours:

- Boolean `contour(Z)` with no caller-supplied levels, no explicit locator, and
  non-log scale selects `levels == [0.5]`.
- Boolean `contourf(Z)` under the same default conditions selects
  `levels == [0, 0.5, 1]`.
- The boolean line default is not replaced by the legacy "no contour levels
  found within the data range" fallback.
- Caller-directed levels and non-default automatic mechanisms remain on the
  existing path.

The proof is partial over the level-selection function.  It does not prove
rendering geometry, contourpy internals, termination of the broader drawing
pipeline, or behavior outside the stated domain.

## Formal Core

The formal abstraction is in:

- `fvk/mini-contour-levels.k`
- `fvk/contour-levels-spec.k`

`processLevels(zIsBool, filled, noLevels, noLocator, logscale, hasInside)`
models the relevant branch in `_process_contour_level_args`.

The output tags denote:

- `lineBoolDefault`: exact level set `[0.5]`
- `filledBoolDefault`: exact level set `[0, 0.5, 1]`
- `callerDirectedLevels`: existing explicit/caller-supplied level path
- `legacyAutomaticLevels`: existing automatic locator/fallback path

## Source-Level Proof

1. `ContourSet.__init__` initializes `_contour_z_is_bool` to false at
   `repo/lib/matplotlib/contour.py:741-743`.  This gives a conservative default
   for contour sets that do not process a new `Z` array.

2. In `contour(Z, ...)`, `_contour_args` first creates `z = ma.asarray(args[0])`,
   records `z.dtype.type is np.bool_`, and only then converts `z` to
   `float64` at `repo/lib/matplotlib/contour.py:1456-1459`.  This discharges
   PO-1 for the one-array call form.

3. In `contour(X, Y, Z, ...)`, `_check_xyz` performs the same ordering for
   `args[2]` at `repo/lib/matplotlib/contour.py:1485-1489`.  This discharges
   PO-1 for the three-array call form.

4. `_process_contour_level_args` enters the default branch only when
   `self.levels is None` and `len(args) == 0` at
   `repo/lib/matplotlib/contour.py:1125-1128`.  Thus explicit positional levels
   and keyword `levels` avoid the boolean default.  This supports PO-5.

5. Inside that default branch, the boolean default guard requires
   `_contour_z_is_bool`, `self.locator is None`, and `not self.logscale` at
   `repo/lib/matplotlib/contour.py:1128-1129`.  Therefore explicit locators,
   log-scale contouring, and non-bool arrays keep the existing automatic path.
   This supports PO-5 and PO-6.

6. When the boolean default guard holds, line contours take `levels_arg = [.5]`
   and filled contours take `levels_arg = [0, .5, 1]` at
   `repo/lib/matplotlib/contour.py:1130`.  Conversion through
   `np.asarray(levels_arg, np.float64)` at
   `repo/lib/matplotlib/contour.py:1138-1141` preserves these numeric level
   values.  This discharges PO-2 and PO-3.

7. The same branch sets `auto_bool_levels = True` at
   `repo/lib/matplotlib/contour.py:1131`.  The line-contour no-inside fallback
   runs only under `not self.filled and not auto_bool_levels` at
   `repo/lib/matplotlib/contour.py:1143-1149`.  Therefore a boolean line
   default remains `[0.5]` even when no contour level is strictly inside the
   data range.  This discharges PO-4.

8. Filled boolean levels have length three and strictly increase.  They pass
   the filled-contour minimum check at `repo/lib/matplotlib/contour.py:1151-1152`
   and the increasing-level check beginning at
   `repo/lib/matplotlib/contour.py:1154`.  This completes PO-3.

9. The public docstring now states the boolean default at
   `repo/lib/matplotlib/contour.py:1592-1594`, discharging PO-7.

## Adequacy Check

The English meaning of the K claims matches the public intent:

- C1 maps directly to the prompt's requested single boundary at `0.5`.
- C2 maps directly to the public hint's `[0, .5, 1]` filled-contour levels.
- C3 and C4 are frame conditions derived from the documented `levels` and
  `locator` behavior, not from hidden tests or candidate-only behavior.

No claim preserves the reported old multi-level boolean default.

## Constructed Machine-Check Commands

These commands are recorded for a future environment with K installed.  They
were not executed in this task.

```sh
cd fvk
kompile mini-contour-levels.k --backend haskell
kast --backend haskell contour-levels-spec.k
kprove contour-levels-spec.k
```

Expected result after machine checking: `kprove` discharges all four claims to
`#Top`.

## Residual Risk

The proof is constructed over a deliberately small abstraction of the branch
logic.  It does not machine-check real Python semantics or NumPy dtype behavior.
That risk is mitigated here by direct source inspection of the actual Python
control flow and by keeping the formal model's observable exactly aligned with
the level-selection property.

No tests were removed or edited.  Any test-redundancy claim would be
conditional on running the emitted K commands and the project test suite in a
real execution environment.
