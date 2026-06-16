# PROOF

Status: constructed, not machine-checked.

## Machine-Check Commands Not Run

The task forbids running K tooling. These are the commands that would be used in
an environment with K installed:

```sh
kompile fvk/mini-matplotlib-widgets.k --backend haskell
kast --backend haskell fvk/span-selector-spec.k
kprove fvk/span-selector-spec.k
```

Expected machine-check result after successful setup: `#Top` for all claims.
This expectation is constructed from the proof below, not observed.

## Mapping From Source To Model

V1 source path:

1. `SpanSelector.__init__` calls `self.new_axes(ax)`.
2. `new_axes` creates `self._rect = Rectangle((0, 0), ...)` with the same
   blended transform as before.
3. V1 attaches the rectangle with `self.ax.add_artist(self._rect)`.
4. If `interactive=True`, `_setup_edge_handle` constructs `ToolLineHandles`.
5. `ToolLineHandles.__init__` creates two `Line2D` handle artists with
   `ax.get_xaxis_transform()` or `ax.get_yaxis_transform()`.
6. V1 attaches each handle with `self.ax.add_artist(artist)`.

Model path:

- `NewSpanSelector(A, true)` rewrites to `NewAxes(A) ~> SetupHandles(A)`.
- `NewAxes(A)` rewrites to `AddArtist(rect, A)`.
- `SetupHandles(A)` rewrites to two `AddArtist(line, A)` operations.
- `AddArtist` increments the helper artist count and frames the data-limit and
  autoscale cells.

## Constructed Proof Of SPAN-HORIZONTAL-INTERACTIVE

Initial state:

- `<k> NewSpanSelector(x, true) </k>`
- `<zeroX> false </zeroX>`
- arbitrary pre-existing `zeroY`, `reqX`, and `reqY`
- rectangle count `R`, line count `L`

Symbolic execution:

1. Apply the constructor rule:
   `NewSpanSelector(x, true) => NewAxes(x) ~> SetupHandles(x)`.
2. Apply the `NewAxes` rule:
   `NewAxes(x) => AddArtist(rect, x)`.
3. Apply the rectangle `AddArtist` rule. It changes only
   `<rects> R => R + 1 </rects>` and leaves `zeroX`, `zeroY`, `reqX`, and
   `reqY` framed.
4. Apply the `SetupHandles` rule:
   `SetupHandles(x) => AddArtist(line, x) ~> AddArtist(line, x)`.
5. Apply the first line `AddArtist` rule. It changes only
   `<lines> L => L + 1 </lines>` and frames the limit/autoscale cells.
6. Apply the second line `AddArtist` rule. It changes only
   `<lines> L + 1 => L + 2 </lines>` and frames the limit/autoscale cells.

Post-state:

- `<k> .K </k>`
- `<zeroX> false </zeroX>`
- `zeroY`, `reqX`, and `reqY` unchanged
- `<rects> R + 1 </rects>`
- `<lines> L + 2 </lines>`

This is exactly claim `SPAN-HORIZONTAL-INTERACTIVE`.

## Constructed Proof Of SPAN-VERTICAL-INTERACTIVE

The proof is identical with axis `y`: `AddArtist(rect, y)` and two
`AddArtist(line, y)` operations frame `zeroY` and `reqY`, while also framing
the unrelated x cells. This proves `SPAN-VERTICAL-INTERACTIVE`.

## Constructed Proof Of SPAN-HORIZONTAL-NONINTERACTIVE

Initial state uses `<k> NewSpanSelector(x, false) </k>`.

1. Apply the noninteractive constructor rule:
   `NewSpanSelector(x, false) => NewAxes(x)`.
2. Apply `NewAxes(x) => AddArtist(rect, x)`.
3. Apply rectangle `AddArtist`.

Post-state has one additional rectangle, no additional lines, and unchanged
data-limit/autoscale cells. This proves `SPAN-HORIZONTAL-NONINTERACTIVE`.

## Constructed Proof Of SPAN-V0-BUG-LOCALIZATION

Initial state models the old horizontal helper attachment path:
`AddPatch(rect, x) ~> AddLine(line, x) ~> AddLine(line, x)`.

1. `AddPatch(rect, x)` sets `zeroX` to `true`, modeling
   `_update_patch_limits` on the initial rectangle at x=0.
2. The first `AddLine(line, x)` keeps `zeroX=true` and sets `reqX=true`,
   modeling `axvline`/`add_line` plus autoscale request.
3. The second `AddLine(line, x)` preserves those polluted/requested states.

Post-state reaches `zeroX=true` and `reqX=true`, matching the reported symptom:
the next x autoscale can include the helper coordinate `0`.

## Adequacy And Completeness Check

The proof covers the full reported construction-time behavior space: horizontal
interactive construction, the symmetric vertical mode, the noninteractive
constructor path, and the old path that generated the bug. Event handling after
selection is not part of the reported failure and is not used to justify the
constructor fix.

## Test Recommendation

No tests were modified. Future public tests should keep a constructor-level
assertion that horizontal interactive `SpanSelector` preserves x limits for
data away from zero, and a symmetric vertical assertion would be useful. Do not
delete tests based on this proof unless the K commands above are later run and
return `#Top`.
