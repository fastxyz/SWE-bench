# PROOF OBLIGATIONS

Status: constructed, not machine-checked.

## O1 - Nominal coordinate detection

Obligation: the finalization branch must apply to any coordinate axis whose
compiled scale is an instance of `Nominal`, covering both explicit and inferred
nominal scales.

Evidence: E1 and E5. Source hook: `repo/seaborn/_core/plot.py:1644-1648`.

Discharge: V1 imports `Nominal`, reads `scale = self._scales.get(axis_key)`, and
uses `isinstance(scale, Nominal)`.

## O2 - Category count supports half-step bounds

Obligation: when no explicit limit is present, finalization must derive the
number of categorical positions, including categories already registered on the
Matplotlib axis where available.

Evidence: E2 and E7. Source hook: `repo/seaborn/_core/plot.py:1627-1635`.

Discharge: V1 uses the Matplotlib category unit mapping when available, and
falls back to tick count, matching the existing categorical approach when the
mapping is unavailable.

## O3 - Grid suppression

Obligation: nominal coordinate grid lines are disabled even under a grid-enabled
style.

Evidence: E3 and E7. Source hook: `repo/seaborn/_core/plot.py:1647-1648`.

Discharge: V1 calls `axis_obj.grid(False)` for every nominal coordinate axis.

## O4 - Default nominal bounds and y inversion

Obligation: for `n > 0` categories and no explicit limit, nominal x limits are
`(-0.5, n - 0.5)` and nominal y limits are `(n - 0.5, -0.5)`.

Evidence: E2, E4, and E7. Source hook:
`repo/seaborn/_core/plot.py:1664-1671`.

Discharge: V1 sets `set_xlim(-.5, n - .5, auto=None)` for x and
`set_ylim(n - .5, -.5, auto=None)` for y.

## O5 - Explicit limit precedence with nominal y inversion

Obligation: explicit `Plot.limit(...)` values are not replaced by default
nominal bounds, but nominal y axes still end inverted.

Evidence: D2 and E4. Source hook: `repo/seaborn/_core/plot.py:1651-1662`.

Discharge: V1 applies converted user limits first. For nominal y, it calls
`invert_yaxis()` if the resulting y axis is not inverted.

## O6 - Non-nominal and semantic frame condition

Obligation: non-nominal coordinate axes and semantic `Nominal` scales are not
changed by the categorical-axis drawing policy.

Evidence: D1. Source hook: `repo/seaborn/_core/plot.py:1644-1664`.

Discharge: V1 gates grid/default-bound behavior on the coordinate `axis_key`
scale being `Nominal`; semantic scales are not iterated as axes in
`_finalize_figure`.

## O7 - Loop coverage over subplots and paired axes

Obligation: every subplot axis gets the same nominal-axis policy, including
paired coordinate keys such as `x0`/`y0`.

Evidence: E5 and E6. Source hook: `repo/seaborn/_core/plot.py:1639-1644`.

Discharge: `_finalize_figure` iterates each subplot and both axes, obtains the
axis key from the subplot record, and looks up that key in `self._scales`.

## O8 - Compatibility

Obligation: the repair must not require public API/callsite changes.

Evidence: public compatibility audit.

Discharge: `_finalize_figure` signature is unchanged; the new helper is private;
public `Plot` methods and object namespace are unchanged.
