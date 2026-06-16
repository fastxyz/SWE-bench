# FVK Spec: Boolean Contour Default Levels

Status: constructed, not machine-checked.  No tests, Python, or K tooling were
run.

## Target

The audited behavior is the level-selection path for regular quadrilateral
`Axes.contour` and `Axes.contourf`, implemented by
`repo/lib/matplotlib/contour.py`.

The observable is `QuadContourSet.levels` after `_contour_args` and
`_process_contour_level_args` have processed `Z` and any caller-provided level
arguments.

## Intent Spec

I1. For a boolean 2D `Z` passed to `contour()` with no levels supplied, the
automatic default must be exactly one contour level at `0.5`.

I2. For a boolean 2D `Z` passed to `contourf()` with no levels supplied, the
automatic default must supply valid filled-contour boundaries `[0, 0.5, 1]`.

I3. The boolean decision must be based on the original input dtype, before the
existing conversion of `Z` to `float64`.

I4. Caller-directed level selection remains caller-directed.  Positional level
arguments, keyword `levels=...`, explicit integer level counts, explicit
locators, and log-scale contouring are not part of the plain default.

I5. Numeric arrays whose values happen to be `0` and `1` are not boolean input
arrays and therefore keep the existing numeric automatic level behavior.

I6. The public docstring for `levels` should mention the new default so the API
contract matches the implementation.

## Public Evidence Ledger

E1. Source: prompt.  Quote: "I find myself fairly regularly calling
`plt.contour(boolean_2d_array, levels=[.5], ...)` to draw the boundary line
between True and False regions."  Obligation: the default for boolean line
contours should select the same boundary without requiring explicit levels.
Status: encoded by C1 and PO-2.

E2. Source: prompt.  Quote: "for boolean inputs, the only choice that makes
sense is to have a single level at 0.5."  Obligation: line contour default is
`[0.5]`, not the normal multi-level locator output.  Status: encoded by C1 and
PO-2.

E3. Source: public hint.  Quote: "For contourf(bool_array) the natural levels
would be [0, .5, 1]."  Obligation: filled boolean contours require a three-level
default.  Status: encoded by C2 and PO-3.

E4. Source: public hint.  Quote: "Levels has an automatic default."  Obligation:
the change belongs to the no-levels automatic default path, not to explicit
caller-provided levels.  Status: encoded by C3 and PO-5.

E5. Source: public docs in `contour_doc`.  Quote: "If an int n..." and "If
array-like..."  Obligation: explicit integer and array-like level inputs keep
their documented meaning.  Status: encoded by C3 and PO-5.

E6. Source: implementation.  `_contour_args` converted `Z` to `float64` before
level selection in both call forms.  Obligation: preserve the original dtype
before conversion so the intent can be implemented.  Status: encoded by PO-1.

E7. Source: implementation/public API.  `Axes.contour` and `Axes.contourf`
construct `mcontour.QuadContourSet`; the issue uses 2D boolean arrays.  Scope:
regular quadrilateral contours are in scope; triangular contour functions are
not required by this issue.  Status: recorded as an explicit scope decision.

## Formal Claims

C1. `processLevels(true, false, true, true, false, HAS)` reaches
`lineBoolDefault`, denoting exact levels `[0.5]`, for either value of `HAS`.

C2. `processLevels(true, true, true, true, false, HAS)` reaches
`filledBoolDefault`, denoting exact levels `[0, 0.5, 1]`, for either value of
`HAS`.

C3. `processLevels(Z, F, false, L, G, H)` reaches `callerDirectedLevels`.
This models explicit positional or keyword level inputs, including integer
level counts, staying on the caller-directed path.

C4. `processLevels(Z, F, true, L, G, H)` reaches `legacyAutomaticLevels`
whenever not `(Z and L and not G)`.  This models non-bool data, explicit
locators, and log-scale contouring staying on the existing automatic path.

The compact formal core is in `fvk/mini-contour-levels.k` and
`fvk/contour-levels-spec.k`.

## Adequacy Audit

C1 passes I1 and I3.  It also covers the all-true/all-false boundary case
because `HAS` is unconstrained and the result remains `lineBoolDefault`.

C2 passes I2 and the filled-contour minimum-level requirement by selecting a
three-element increasing boundary set.

C3 passes I4 by not replacing caller-directed choices with the boolean default.

C4 passes I4 and I5 by preserving existing behavior outside the plain bool
default case.  The explicit `locator` and log-scale exclusions are narrower
than the issue's default case and are supported by the documented locator/log
contracts.

I6 is not part of the K level-selection model.  It is covered by PO-7 and the
source docstring update.

No formal claim depends on hidden tests, evaluator output, or upstream patches.

## Public Compatibility Audit

No public function signatures changed.  `Axes.contour`, `Axes.contourf`, and
`pyplot.contour`/`contourf` still call `QuadContourSet` the same way.

The new `_contour_z_is_bool` attribute is private state initialized on
`ContourSet` and set inside `QuadContourSet` before level processing.  It does
not alter subclass method signatures or public return types.

The only public text change is the `levels` docstring addition documenting the
new boolean defaults.
