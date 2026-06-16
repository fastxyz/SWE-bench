# Public Evidence Ledger

E1. Source: `benchmark/PROBLEM.md`, bug summary.

Quote: "interactive SpanSelector incorrectly forces axes limits to include 0"

Obligation: constructing an interactive `SpanSelector` must not introduce `0`
into the selected axis limits. Status: encoded by claims
`SPAN-HORIZONTAL-INTERACTIVE` and `SPAN-V0-BUG-LOCALIZATION`.

E2. Source: `benchmark/PROBLEM.md`, reproduction.

Quote: `ax.plot([10, 20], [10, 20])` followed by
`SpanSelector(ax, print, "horizontal", interactive=True)`.

Obligation: the construction path for a horizontal interactive selector is in
scope, with existing data away from zero. Status: encoded by
`SPAN-HORIZONTAL-INTERACTIVE`.

E3. Source: `benchmark/PROBLEM.md`, expected outcome.

Quote: "The axes xlimits remain at (10, 20) + margins"

Obligation: data limits and autoscale inputs derived from plotted data must be
preserved; selector helpers are not new plotted data. Status: encoded as the
`zeroX` and `reqX` frame conditions.

E4. Source: `benchmark/PROBLEM.md`, public discussion.

Quote: "this is when calling ss = SpanSelector(... interactive=True) that the
axis limit changes, not when selecting an range"

Obligation: the constructor itself must be audited independently of event
handling. Status: encoded by `NewSpanSelector(..., true)` claims.

E5. Source: `repo/lib/matplotlib/widgets.py`, public docstring.

Quote: `direction : {"horizontal", "vertical"}` and `interactive : bool`

Obligation: both selector directions are valid public modes; the frame
condition should not be hard-coded only to horizontal mechanics. Status:
encoded by `SPAN-VERTICAL-INTERACTIVE`.

E6. Source: `repo/lib/matplotlib/axes/_base.py`, `Axes.add_artist` docstring.

Quote: "Use add_artist only for artists for which there is no dedicated 'add'
method; and if necessary, use a method such as update_datalim to manually
update the dataLim if the artist is to be included in autoscaling."

Obligation: `add_artist` is the intended attachment path when an artist should
not be included in automatic data-limit updates. Status: used as code evidence
for proof obligations PO2 and PO3.

E7. Source: `repo/lib/matplotlib/axes/_base.py`, `add_patch` and `add_line`.

Quote: `add_patch` calls `_update_patch_limits`; `add_line` calls
`_update_line_limits`.

Obligation: the old helper attachment path can mutate data limits. Status:
encoded by the V0 bug-localization claim and Finding F1.

E8. Source: `repo/lib/matplotlib/axes/_axes.py`, `axvline`/`axhline`.

Quote: these methods call `add_line` and `_request_autoscale_view(...)`.

Obligation: the old interactive handle path can both mutate data limits and
request autoscale. Status: encoded by the V0 bug-localization claim and
Finding F1.
