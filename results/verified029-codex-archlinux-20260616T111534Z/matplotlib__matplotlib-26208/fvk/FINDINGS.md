# FVK Findings

Status: constructed, not machine-checked. Findings are derived from public
intent and source inspection only.

## F1: Pre-V1 defect localized to late shared-axis unit broadcast

Input path: `ax1.stackplot(string_x, y1)`, then `ax2 = ax1.twinx()`, then
`ax2.plot(string_x, y2)`.

Observed pre-fix behavior from the issue: `ax1.dataLim.intervaly` becomes
`[inf, -inf]`.

Expected behavior from prompt evidence E1/E2: `ax1.dataLim.intervaly` remains
the stackplot interval because no data was added to `ax1`.

Source localization: before V1, the fresh twin x-axis had no units. During
`ax2.plot`, `_process_unit_info()` would call `ax2.xaxis.update_units()`,
which would create a new categorical unit object and call `set_units()` on the
shared x-axis group. That fires `ax1`'s units callback, which calls `relim()`.
`relim()` resets `dataLim` and does not include `Collection` instances, so a
stackplot-only data limit becomes null.

Status: resolved by V1 if PO1-PO4 hold.

## F2: V1 satisfies the reported preservation path

Input path: same as F1, but with V1 applied.

Observed from source inspection: `sharex()` copies `other.xaxis.converter` and
`other.xaxis.units` into the receiving x-axis when the receiving x-axis has no
units.

Expected behavior: `ax2.xaxis.have_units()` is true before `ax2.plot` processes
string x data, so `_process_unit_info()` does not call `update_units()` for x.
The shared x-axis group is not assigned a replacement categorical unit object,
and `ax1._unit_change_handler("x")` is not invoked.

Status: confirmed by PO1-PO4; V1 stands for the reported issue.

## F3: Existing receiving-axis units should not be overwritten

Input path: public `sharex()` / `sharey()` called on an axes that already has
unit state.

Observed V1 behavior: the copy happens only under `if not self.xaxis.have_units()`
or `if not self.yaxis.have_units()`.

Expected behavior: public compatibility is best preserved by not clobbering
established unit state on a non-fresh receiving axes. The issue path uses a
fresh twin axis, so this guard does not weaken the reported fix.

Status: confirmed by PO5; no V2 change required.

## F4: Symmetric `sharey()` edit is justified

Input path: analogous `twiny()` / shared-y case where an original axes has y
units and the receiving y-axis is fresh.

Observed V1 behavior: `sharey()` mirrors the `sharex()` unit copy.

Expected behavior: the public sharing contract is axis-symmetric. Although the
reported reproduction is `twinx()`, the same unit-broadcast mechanism can occur
on a shared y-axis.

Status: confirmed by PO6; no V2 change required.

## F5: Broad `Axes.relim()` collection support is not the selected repair

Alternative considered: change `Axes.relim()` to include `Collection`
instances so the callback would reconstruct stackplot limits after the late
unit update.

Reason rejected: the public issue expects no change to `ax1.dataLim` because
no data was added to `ax1`; it does not require a global change to relim
collection semantics. The source explicitly documents that collections are
not currently supported by `relim()`. PO3 localizes the operative defect to
the unnecessary late shared-unit broadcast, so preventing that broadcast
satisfies the public intent with a smaller compatibility surface.

Status: rejected on positive intent and compatibility grounds, not merely on
diff scope.

## Proof-Derived Findings

No proof obligation required a V2 production edit beyond V1. The constructed
proof leaves these residual risks:

- The proof is constructed, not machine-checked.
- The mini-K model abstracts away full Matplotlib rendering and autoscaling.
- No test-redundancy deletion is recommended without later machine checking.
