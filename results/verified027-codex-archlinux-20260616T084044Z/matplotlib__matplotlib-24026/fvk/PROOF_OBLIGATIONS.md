# FVK Proof Obligations

Status: constructed, not machine-checked.

## Domain

D1. `M >= 1`, where `M` is the number of stacked y-series.

D2. If `colors is not None`, `colors` is a finite, non-empty iterable of
artist-valid color specifications. `C<N>` aliases are included in this domain.

D3. If `colors is None`, the Axes object has the normal Matplotlib
`_get_lines.get_next_color` color-source behavior, with a non-negative current
cycle position.

## Obligations

PO1. Explicit branch selection.

Given `colors is not None`, execution enters the explicit-colors branch and
constructs only a local color cycle. It does not call
`axes.set_prop_cycle(color=colors)`.

Findings: F1, F2.

PO2. Explicit cyclic facecolors.

Given `colors = [c0, ..., cN-1]`, `N > 0`, and `M` stacked layers, stackplot
passes `facecolor = colors[i mod N]` to the `i`th `fill_between` call for every
`0 <= i < M`.

Findings: F1.

PO3. `C<N>` aliases avoid prop-cycle validation.

Given an explicit color value like `C2`, stackplot must pass that value to
artist color handling (`fill_between(..., facecolor='C2')`) rather than to
`axes.set_prop_cycle`, because the property-cycle validator intentionally
rejects cycle references.

Findings: F1.

PO4. Explicit Axes cycler frame.

Given explicit `colors`, the Axes line color source before and after color
selection is identical. No replacement and no advancement of
`axes._get_lines` is permitted on this path.

Findings: F2.

PO5. Default-color frame.

Given `colors is None`, stackplot keeps legacy behavior: each stacked layer
gets `axes._get_lines.get_next_color()`, so the Axes line color source advances
once per layer. This obligation is intentionally not strengthened to
no-advance behavior.

Findings: F3.

PO6. Public compatibility.

The patch must not change the `stackplot` signature, return shape, wrapper
dispatch through `Axes.stackplot` or `pyplot.stackplot`, or the
`fill_between` producer contract.

Findings: F5.

PO7. Non-color frame.

Baseline calculation, cumulative stack construction, label handling,
`kwargs` forwarding, sticky edges, and collection return order remain as in the
pre-existing implementation.

Findings: F6.

## K-Style Claim Map

`fvk/stackplot-spec.k` contains the following constructed claims:

- `CLAIM-EXPLICIT-COLORS` discharges PO1 and PO2.
- `CLAIM-EXPLICIT-AXES-FRAME` discharges PO4.
- `CLAIM-CN-NO-PROP-CYCLE-VALIDATOR` discharges PO3.
- `CLAIM-DEFAULT-LEGACY-CYCLE` discharges PO5.
- `CLAIM-PUBLIC-COMPAT-FRAME` records PO6 and PO7 as frame obligations.

No loop circularity is needed in the abstract color model because the repeated
layer behavior is represented by the `takeCycle` spec function. In source-code
terms, the first layer plus the `for i in range(len(y) - 1)` loop correspond
to induction over the number of emitted facecolors; the induction hypothesis is
the prefix property of `takeCycle`.
