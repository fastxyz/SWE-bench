# FVK Findings

Status: constructed, not machine-checked. Findings are from public intent,
source inspection, and proof construction only.

## F1 - Resolved Code Bug: explicit `C<N>` colors went through prop-cycle validation

Input: `ax.stackplot([1, 2, 3], my_data, colors=['C2', 'C3', 'C4'])`.

Observed before V1: `stackplot` called `axes.set_prop_cycle(color=colors)`;
the property-cycle validator rejected `C2` with
`Cannot put cycle reference ('C2') in prop_cycler`.

Expected: each `C<N>` value should be passed as an artist facecolor, like
`ax.plot(..., color='C0')` and `Rectangle(..., facecolor='C1')`.

V1 status: fixed. The explicit-colors branch now uses a local
`itertools.cycle(colors)` and passes each value to `fill_between` as
`facecolor`.

Proof obligations: PO1, PO2, PO3.

## F2 - Resolved Code Bug: explicit `colors=` replaced the Axes property cycle

Input: any non-empty explicit color sequence, for example
`colors=['C2', 'C3', 'C4']`.

Observed before V1: `axes.set_prop_cycle(color=colors)` replaced the Axes
property cycle for future plotting commands.

Expected: the `colors=` argument is local to the stackplot call; it should not
reset the Axes cycle.

V1 status: fixed. No call to `axes.set_prop_cycle` remains in
`stackplot.py`, and the explicit-colors branch does not call
`axes._get_lines.get_next_color`.

Proof obligations: PO1, PO4.

## F3 - Ambiguity: whether omitted colors should preserve cycle position

Input: `ax.stackplot(x, y1, y2, y3)` with `colors is None`.

Observed in V1 and legacy code: the default path calls
`axes._get_lines.get_next_color` once per stack layer, advancing the Axes line
color iterator.

Possible broader expectation: the issue title alone could be read as
"stackplot should never advance or otherwise affect the Axes cycler."

Decision: no source change. The docstring says omitted colors use the Axes
property cycle, and Matplotlib default color consumption normally advances the
cycle. The reported traceback and reproducer are both on the explicit
`colors=` path. Treating the no-`colors` path as a no-advance snapshot would be
a broader compatibility change without enough public evidence.

Proof obligations: PO5.

## F4 - Boundary: empty explicit color sequences remain unspecified

Input: `colors=[]`.

Observed by inspection: V1 would build an empty `itertools.cycle` and fail when
the first color is requested. Legacy behavior would also not provide a usable
layer color after installing an empty property cycle.

Expected: not specified by the issue or docstring. `colors` is described as a
sequence of colors to cycle through; an empty sequence cannot supply a color.

Decision: no source change. This is outside the proved domain. A future API
cleanup could add an explicit `ValueError`, but that is not required by this
issue.

Proof obligations: domain precondition for PO1.

## F5 - Compatibility Finding: no public API or dispatch shape changed

Input: existing calls through `Axes.stackplot` and `pyplot.stackplot`.

Observed in V1: the function signature is unchanged; return type remains a
list of `PolyCollection`; `fill_between` is still the producer of those
collections.

Expected: existing stackplot callers and wrappers continue to work.

Decision: V1 stands. No compatibility repair is needed.

Proof obligations: PO6.

## F6 - Proof Boundary: numeric stacking is framed, not re-proved

Input: any stackplot baseline mode (`zero`, `sym`, `wiggle`,
`weighted_wiggle`).

Observed in V1: baseline and stack computation code is unchanged.

Expected: the issue does not request a change to area geometry.

Decision: no source change. The FVK claims prove the changed color-selection
contract and frame the unmodified numeric behavior. Hidden geometry or image
tests should remain governed by the existing implementation and public tests.

Proof obligations: PO7.
