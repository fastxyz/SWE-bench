# SPEC

Status: constructed, not machine-checked.

## Scope

Target: `repo/lib/matplotlib/widgets.py`, specifically the construction path
for `SpanSelector` and its `ToolLineHandles` edge handles.

The public issue is construction-time behavior: calling
`SpanSelector(ax, print, "horizontal", interactive=True)` after plotting data
near `[10, 20]` must not expand the x limits to include `0`.

## Intent-Derived Contract

S1. `SpanSelector` construction must be a frame operation over plotted data
limits. It may add widget helper artists, but those helpers are not plotted
data and must not introduce their initial coordinate `0` into `Axes.dataLim`.

S2. Interactive construction must preserve pre-existing autoscale-request state.
It must not add a new autoscale request merely because the initial selector
helper coordinate is `0`.

S3. The widget must still create and attach the internal rectangle and, when
`interactive=True`, two edge-handle lines. The fix must not remove the UI
elements needed by selection, dragging, visibility toggling, or blitting.

S4. The selected data axis depends on `direction`: horizontal selectors use
x-data coordinates and vertical selectors use y-data coordinates. The same
helper-artist frame condition applies to either direction.

S5. Public signatures and test files remain unchanged.

## Evidence Summary

The full ledger is in `PUBLIC_EVIDENCE_LEDGER.md`.

- E1-E4 derive the construction-time no-zero-in-limits behavior directly from
  `benchmark/PROBLEM.md`.
- E5 derives horizontal/vertical mode coverage from the `SpanSelector`
  docstring.
- E6 identifies `Axes.add_artist` as the local API path for artists that should
  not be included in autoscaling.
- E7-E8 localize the old bug to `add_patch`/`add_line` and
  `axvline`/`axhline`.

## Formal Model

The K fragment is `mini-matplotlib-widgets.k`.

It abstracts an axes state to the minimum observable needed for this issue:

- `zeroX` / `zeroY`: whether the selector helper coordinate `0` has entered the
  corresponding data-limit state.
- `reqX` / `reqY`: whether the corresponding autoscale request flag is present.
- `rects` / `lines`: counts of attached rectangle and line helper artists.

This abstraction distinguishes a passing instance from the reported failing
instance:

- Passing: helper artists are attached, but `zeroX` remains `false`.
- Failing: helper artists attach through data-limit-aware paths and `zeroX`
  becomes `true`.

## Claims

The claims are in `span-selector-spec.k`.

C1. `SPAN-HORIZONTAL-INTERACTIVE`: horizontal interactive construction adds one
rectangle and two line handles while preserving `zeroX`, `zeroY`, `reqX`, and
`reqY`.

C2. `SPAN-VERTICAL-INTERACTIVE`: vertical interactive construction preserves the
same frame condition on the y data axis.

C3. `SPAN-HORIZONTAL-NONINTERACTIVE`: noninteractive construction adds only the
rectangle helper and preserves the data-limit/autoscale frame.

C4. `SPAN-V0-BUG-LOCALIZATION`: the old `add_patch` plus
`add_line`/`axvline` mechanism is sufficient to insert `0` into x data limits
and request x autoscaling. This is a bug witness, not an intended behavior.

## Adequacy

`FORMAL_SPEC_ENGLISH.md` paraphrases each claim, and `SPEC_AUDIT.md` checks the
paraphrase against `INTENT_SPEC.md`. All claims pass the adequacy audit. No
claim preserves the legacy behavior described as buggy by the issue.
