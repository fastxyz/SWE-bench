# Baseline Notes

## Root cause

The failure is caused by a late unit update on a shared categorical x-axis.
After `ax1.stackplot(...)`, `ax1` has categorical x units and its y data limits
come from `fill_between`, which adds a `PolyCollection`. Creating `ax2 =
ax1.twinx()` shares the x-axis ticker and limits, but the new axis did not
inherit the x-axis converter or units from `ax1`.

When `ax2.plot(...)` later receives string x data, `ax2.xaxis.update_units`
creates a new categorical `UnitData` object and broadcasts it to every shared
x-axis. That invokes the units callback on `ax1`, whose handler calls
`relim()`. `Axes.relim()` intentionally does not include `Collection`
instances, so the stackplot-only limits on `ax1` are reset to a null
`Bbox`, which appears as `[inf, -inf]`.

## Changed files

`repo/lib/matplotlib/axes/_base.py`

`sharex()` and `sharey()` now copy the converter and unit object from the axis
being shared when the receiving axis has no unit state yet. For the reported
`twinx()` case, the new twin therefore uses the existing categorical
`UnitData` from `ax1` instead of creating and broadcasting a replacement unit
object back to `ax1`. The same logic is applied to `sharey()` for symmetry and
for the analogous `twiny()` shared-y case.

## Assumptions and alternatives considered

I assumed that an axis newly sharing with another axis should inherit the
shared axis' unit conversion state when it has not established its own units.
That matches the existing sharing behavior for ticker state, limits, and scale,
and keeps later plotting on the shared axis within the same unit mapping.

I considered changing `Axes.relim()` to include `Collection` instances, but the
source explicitly documents that collections are not supported there, and such
a change would be much broader than this issue. I also considered suppressing
unit callbacks or adding categorical `UnitData` equality checks, but those
would either hide legitimate unit changes or solve only this categorical
variant. Copying unit state at share creation fixes the specific late-unit
broadcast that corrupts the original axes while keeping the change localized.
