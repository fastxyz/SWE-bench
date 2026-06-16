# Intent Spec

Status: constructed from public intent, before accepting V1 behavior as the spec.

## Required behaviors

I1. `so.Nominal` coordinate scales must be drawn like seaborn categorical axes.
Source: issue title, "Nominal scale should be drawn the same way as categorical scales."

I2. The default nominal coordinate extent must cover the first through last
category with half-step padding: `-.5` before the first position and `+.5`
after the last position. Source: issue item 1.

I3. Nominal coordinate grid lines must be disabled even when the active style
would otherwise draw them. Source: issue item 2.

I4. A nominal y coordinate axis must be inverted. Source: issue item 3.

I5. The behavior applies to explicit `so.Nominal` coordinate scales and scales
inferred as nominal. Source: issue phrase "`so.Nominal` scales (including
inferred ones)".

I6. The behavior should be applied during final figure handling after plotting
and autoscaling, unless a more precise implementation point is required. Source:
issue implementation note naming `Plotter._finalize_figure` and categorical
code comments explaining that early categorical limit adjustment is overwritten
by autoscaling.

## Domain and frame assumptions

D1. These obligations concern coordinate axes (`x`, `y`, and paired variants),
not semantic properties such as color or marker.

D2. Explicit user limits remain user limits; the public issue describes default
drawing behavior, not removal of `Plot.limit(...)`.

D3. The default half-step extent is only meaningful when the nominal axis has at
least one category/tick. Empty nominal axes are not specified by the issue.

D4. Matplotlib category positions are consecutive integers beginning at `0`.
This is a named default-domain assumption already relied on by seaborn's
categorical-axis code and object nominal conversion.
