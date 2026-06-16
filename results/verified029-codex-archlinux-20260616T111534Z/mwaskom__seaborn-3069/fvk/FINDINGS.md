# FINDINGS

Status: constructed, not machine-checked. No hidden tests or execution results
were used.

## F1 - V1 covers the reported nominal default axis behavior

Classification: resolved issue / no additional code bug found.

Input class: a plot with a nominal coordinate axis, no explicit `Plot.limit`, and
`n > 0` categories.

Observed in V1: `_finalize_figure` detects `Nominal`, disables the grid, and
sets x limits to `(-.5, n - .5)` or y limits to `(n - .5, -.5)`.

Expected from intent: categorical-style half-step limits, no grid, and y-axis
inversion.

Trace: obligations O1, O3, O4.

Decision: V1 stands for this input class.

## F2 - V1 covers inferred nominal coordinate scales

Classification: resolved issue / no additional code bug found.

Input class: a coordinate variable whose scale was inferred as `Nominal` rather
than explicitly passed as `so.Nominal()`.

Observed in V1: finalization checks the compiled scale object in
`self._scales`, not the user scale specification.

Expected from intent: "including inferred ones".

Trace: obligations O1 and O7.

Decision: V1 stands for inferred nominal axes.

## F3 - Explicit nominal y limits are preserved and still inverted

Classification: confirmed design choice.

Input class: nominal y axis with `Plot.limit(y=(lo, hi))`.

Observed in V1: finalization applies the converted explicit limit, then inverts
the y axis if the resulting limit order is not already inverted.

Expected from intent: the issue requires nominal y axes to be inverted, while it
does not state that explicit user limits should be discarded.

Trace: obligation O5.

Decision: keep V1 unchanged. Replacing explicit limits with default categorical
bounds would violate the existing `Plot.limit` contract without public evidence.

## F4 - Empty nominal axes are under-specified

Classification: underspecified intent, non-blocking.

Input class: nominal coordinate axis with no categories (`n <= 0`) and no
explicit limit.

Observed in V1: the grid is disabled, but no categorical default limits are set.

Expected from intent: the issue does not describe empty nominal axes. Existing
categorical code avoids setting limits when there is no categorical data.

Trace: obligation O2 and `SPEC_AUDIT.md` C6.

Decision: no source edit. Hidden behavior should not be guessed from an
under-specified boundary case; V1 avoids meaningless empty categorical limits.

## F5 - Matplotlib unit mapping is an abstraction boundary

Classification: proof capability gap / integration risk.

Input class: nominal coordinate axis whose category count is obtained through
Matplotlib's converter/unit internals.

Observed in V1: `_nominal_axis_length` uses `axis.units._mapping` when present
and falls back to tick count.

Expected from intent: count the categorical positions used to draw the axis.

Trace: obligation O2.

Decision: no source edit. This choice is justified as a robust version of the
existing categorical tick-count approach, but integration tests should remain
because the constructed K model abstracts Matplotlib internals.

## Proof-derived findings from `/verify`

No proof obligation forced a V2 code change. The only non-passing adequacy item
is the empty-axis ambiguity in F4, which is outside the public issue's specified
behavior and does not contradict V1.
