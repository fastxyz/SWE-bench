# PROOF OBLIGATIONS

Status: constructed, not machine-checked.

## PO1: Intent Adequacy

Statement: the formal claims must express the public issue's required behavior,
not the V1 implementation's behavior by itself.

Evidence: `INTENT_SPEC.md`, `PUBLIC_EVIDENCE_LEDGER.md`,
`FORMAL_SPEC_ENGLISH.md`, and `SPEC_AUDIT.md`.

Discharge: pass. The claims state a construction-time frame condition over
data limits and autoscale requests, and isolate the old behavior only as a bug
witness.

## PO2: Span Rectangle Must Not Update Data Limits

Statement: `SpanSelector.new_axes` must attach the invisible rectangle without
calling `_update_patch_limits`.

Evidence: V1 calls `self.ax.add_artist(self._rect)`. `Axes.add_artist` appends
the artist, sets artist properties, clips it to the axes patch, and marks the
axes stale; it does not call `_update_patch_limits` or `update_datalim`.

Discharge: pass. This proves the rectangle helper does not introduce its
initial `0` coordinate into `dataLim`.

## PO3: Interactive Edge Handles Must Not Update Data Limits Or Request Autoscale

Statement: `ToolLineHandles.__init__` must create the two edge lines without
using `axvline`/`axhline` or `Axes.add_line`.

Evidence: V1 constructs `Line2D([p, p], [0, 1], transform=ax.get_xaxis_transform(), ...)`
for horizontal handles and `Line2D([0, 1], [p, p], transform=ax.get_yaxis_transform(), ...)`
for vertical handles, then attaches each with `self.ax.add_artist(artist)`.

Discharge: pass. `add_artist` does not call `_update_line_limits` or
`_request_autoscale_view`, so the initial handle coordinate `0` does not enter
data limits and does not request autoscaling.

## PO4: Widget Geometry And Handle Semantics Must Be Preserved

Statement: the no-autoscale fix must keep the same rectangle/handle geometry
needed by `extents`, `positions`, `set_data`, visibility control, and removal.

Evidence: the rectangle creation code is unchanged except for the attachment
method. The direct `Line2D` construction uses the same x/y data arrays and the
same blended transforms as `axvline`/`axhline`: horizontal handles have x in
data coordinates and y in axes coordinates; vertical handles have x in axes
coordinates and y in data coordinates.

Discharge: pass. The state modeled by `rects` and `lines` reaches one
rectangle and two lines for interactive construction, and source inspection
shows the public helper methods still operate on the same line data fields.

## PO5: Root Cause Must Reproduce The Reported Symptom Symbolically

Statement: the formal model must localize how the pre-V1 constructor could put
`0` into x data limits.

Evidence: the old rectangle path was `add_patch`; the old handle path was
`axvline`/`axhline`, which route through `add_line` and request autoscale.

Discharge: pass. `SPAN-V0-BUG-LOCALIZATION` reaches `zeroX=true` and
`reqX=true` from a horizontal old-style construction path.

## PO6: Public Compatibility Must Be Preserved

Statement: the fix must not change public signatures, virtual dispatch
requirements, test files, or the documented selector API.

Evidence: `PUBLIC_COMPATIBILITY_AUDIT.md`.

Discharge: pass. No signature changed; no public override/callsite break was
found in local source; tests were not modified.

## PO7: No Execution Claims

Statement: because the task forbids execution, the proof must be labeled
constructed, not machine-checked, and tests must not be declared redundant
without a future `kprove` run.

Evidence: task instructions and `PROOF.md` command section.

Discharge: pass. No tests, Python, or K tooling were run; all proof artifacts
state this limitation.
