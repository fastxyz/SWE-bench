# FVK Findings

Constructed, not machine-checked.

## F-1: V1 Fixes The Reported Destructive Re-Resolution

**Input/state:** global `rcParams["backend"] == auto`, pyplot is imported,
`pyplot._backend_mod` is set, selected backend is concrete `B`, and
`Gcf.figs == FS`.

**V0 observed behavior:** `get_backend()` calls `switch_backend(auto)`;
`switch_backend()` calls `close("all")`; `Gcf.figs` becomes empty.

**Expected behavior:** `get_backend()` returns `B` and leaves `Gcf.figs == FS`.

**V1 behavior by inspection:** the loaded-backend branch repairs
`rcParams["backend"]` from the selected backend and does not call
`switch_backend()`.

**Related obligations:** PO-1, PO-3.

**Classification:** code bug fixed by V1.

## F-2: V1 Preserves Initial Lazy Backend Resolution

**Input/state:** global `rcParams["backend"] == auto` and pyplot has no loaded
backend.

**Expected behavior:** backend lookup may still resolve the sentinel through
`switch_backend(auto)`.

**V1 behavior by inspection:** the new branch is gated on `_backend_mod`; when
that is absent, the existing import-and-switch path remains.

**Related obligations:** PO-2.

**Classification:** compatibility preserved.

## F-3: V1 Does Not Weaken Real Backend Switch Cleanup

**Input/state:** public code calls `pyplot.switch_backend(newbackend)`.

**Expected behavior:** existing switch cleanup may close all figures.

**V1 behavior by inspection:** `pyplot.switch_backend()` is unchanged.

**Related obligations:** PO-5, PO-6.

**Classification:** compatibility preserved.

## F-4: Non-Global RcParams Behavior Remains Out Of The Repair Path

**Input/state:** a standalone `RcParams` object contains the auto sentinel.

**Expected behavior:** accessing `["backend"]` on that standalone object does
not perform global pyplot backend resolution.

**V1 behavior by inspection:** the new branch is inside the existing global
`rcParams` identity check.

**Related obligations:** PO-4, PO-6.

**Classification:** compatibility preserved.

## F-5: Proof Is Constructed, Not Machine-Checked

The K artifacts and proof obligations were written but not run through
`kompile`, `kast`, or `kprove` because the task forbids K tooling execution.

**Related obligations:** all.

**Classification:** proof honesty caveat, not a source-code defect.
