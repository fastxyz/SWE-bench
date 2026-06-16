# FINDINGS

Status: constructed, not machine-checked.

## F1: V0 Constructor Path Polluted Data Limits

Classification: code bug in the pre-V1 implementation.

Evidence: `Axes.add_patch` calls `_update_patch_limits`; `Axes.add_line` calls
`_update_line_limits`; `axvline`/`axhline` also call
`_request_autoscale_view`. The old `SpanSelector.new_axes` used `add_patch` for
an invisible rectangle at `(0, 0)`, and interactive edge handles were created
with `axvline`/`axhline` at the initial extents `(0, 0)`.

Observed vs expected: for `ax.plot([10, 20], [10, 20])` followed by horizontal
interactive construction, the old path can introduce x=0 into the x data limits;
the expected behavior is to keep the plotted-data x limits plus margins.

Proof link: PO5 and claim `SPAN-V0-BUG-LOCALIZATION`.

## F2: V1 Removes The Autoscale-Causing Attachment Paths

Classification: confirmation of V1 against the construction-time intent.

Evidence: V1 uses `Axes.add_artist` for the span rectangle. V1 also constructs
the two edge handles directly as `Line2D` objects with blended axis transforms
and attaches them with `Axes.add_artist`, avoiding `axvline`/`axhline`.

Expected outcome: helper artists are present, but `dataLim` and autoscale
request state are framed. This satisfies the public issue's expected
construction behavior.

Proof link: PO2, PO3, claims `SPAN-HORIZONTAL-INTERACTIVE`,
`SPAN-VERTICAL-INTERACTIVE`, and `SPAN-HORIZONTAL-NONINTERACTIVE`.

## F3: V1 Preserves The Required Helper Artists

Classification: compatibility confirmation.

Evidence: the rectangle is still a `Rectangle` with the same x-axis or y-axis
blended transform, initial geometry, visibility, and `rectprops`. The handles
are still `Line2D` instances with the same blended transforms and data layout
used by `positions` and `set_data`.

Expected outcome: `SpanSelector` retains its visible span and interactive edge
handles while no longer treating those helper artists as plotted data.

Proof link: PO4.

## F4: No Public API Or Test-File Change Is Justified

Classification: compatibility confirmation.

Evidence: no public signature changed; local callsites of `ToolLineHandles`
remain compatible; the task forbids modifying tests. The behavioral change is
limited to data-limit/autoscale participation of widget helper artists.

Proof link: PO6.

## F5: Proof Is Constructed, Not Machine-Checked

Classification: proof honesty / residual risk.

Evidence: the task forbids running K tooling, tests, Python, or project code.
The K semantics and claims were therefore written and reasoned about, but not
executed with `kompile` or `kprove`.

Recommended action: keep tests; condition any test-redundancy decision on a
future machine check returning `#Top`. No source change is required by this
finding.

Proof link: PO7.

## Open Findings

No open code bug was found in V1 for the public construction-time limit
regression. V1 stands unchanged.
