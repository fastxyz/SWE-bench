# FVK Spec: Axes3D Visibility

Status: constructed, not machine-checked. No tests, Python, `kompile`, or `kprove` were run.

Formal core:

- `fvk/mini-mpl3d-draw.k`
- `fvk/axes3d-visible-spec.k`

## Intent Spec

I1. When a 3D axes has `set_visible(False)`, drawing the figure must not render that axes. The issue evidence is the reproduction line `ax1.set_visible(False)` and the expected outcome: "The left axes should be invisible."

I2. `Axes3D` is an `Artist`/`Axes` subclass. The inherited `Artist.draw` contract says drawing has no effect if the artist is not visible, and `Axes.draw` checks for `renderer is None` before checking visibility.

I3. Visible 3D axes should preserve existing behavior: draw the 3D background patch, aspect/projection updates, 3D child projection/zordering, panes, axes, and then delegate the rest to the base axes drawing path.

I4. Layout/tightbbox behavior should match the same visibility contract: an invisible axes should not contribute a tight bounding box. `Axes.get_tightbbox` returns `None` when the axes is not visible.

## Public Evidence Ledger

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "`ax1.set_visible(False)`" and "The left axes should be invisible." | Invisible `Axes3D.draw` must produce no draw side effects. | Encoded by `DRAW-INVISIBLE`. |
| E2 | `benchmark/PROBLEM.md` | "the subplot remains visible which should not happen if the value is set to False" | The failure is axes-level visibility, not merely child artist visibility. | Encoded by `DRAW-INVISIBLE`; adjacent per-axis behavior is not part of this patch. |
| E3 | `repo/lib/matplotlib/artist.py` | `Artist.draw` documents no effect when `get_visible()` is false. | Overridden draw methods must honor `get_visible()`. | Encoded by `DRAW-INVISIBLE`. |
| E4 | `repo/lib/matplotlib/axes/_base.py` | `Axes.draw` raises `RuntimeError('No renderer defined')` before its visibility return. | `Axes3D.draw` should preserve the renderer precondition ordering. | Encoded by `DRAW-NONE-RENDERER`; caused the V2 refinement. |
| E5 | `repo/lib/matplotlib/axes/_base.py` | `Axes.get_tightbbox` returns `None` when not visible. | `Axes3D.get_tightbbox` should preserve `None` and skip 3D bbox union for invisible axes. | Encoded by `BBOX-INVISIBLE`. |

## Formal Spec English

`DRAW-INVISIBLE`: for any valid renderer and `visible == false`, `Axes3D.draw` reaches normal return after only the visibility-return event. It does not unstale limits, draw the patch, apply aspect, compute projection, project children, draw panes, draw axes, or delegate to `Axes.draw`.

`DRAW-NONE-RENDERER`: for `renderer is None`, `Axes3D.draw` raises the same no-renderer error before any visibility-dependent return.

`DRAW-VISIBLE-FRAME`: for a valid renderer and `visible == true`, `Axes3D.draw` preserves the existing visible draw sequence through projection, 3D pane/axis drawing, and base draw delegation.

`BBOX-INVISIBLE`: when the base tightbbox result is `None` because the axes is invisible, `Axes3D.get_tightbbox` returns `None` and performs no 3D-axis bbox union.

`BBOX-VISIBLE-FRAME`: when the base tightbbox exists for a visible axes, `Axes3D.get_tightbbox` preserves the existing extension that unions visible 3D axis bboxes.

## Adequacy Audit

| Claim | Intent coverage | Result |
| --- | --- | --- |
| `DRAW-INVISIBLE` | Directly covers I1 and E1/E3. | Pass. |
| `DRAW-NONE-RENDERER` | Covers I2/E4 compatibility with `Axes.draw`. | Pass after V2; V1 failed this ordering. |
| `DRAW-VISIBLE-FRAME` | Covers I3 frame condition for visible axes. | Pass. |
| `BBOX-INVISIBLE` | Covers I4/E5. | Pass. |
| `BBOX-VISIBLE-FRAME` | Covers I4 frame condition for visible axes. | Pass. |

## Public Compatibility Audit

Changed public methods:

- `mpl_toolkits.mplot3d.axes3d.Axes3D.draw(self, renderer)`: signature unchanged. V2 preserves the inherited no-renderer error and adds the inherited no-effect behavior for invisible artists before 3D-specific side effects.
- `mpl_toolkits.mplot3d.axes3d.Axes3D.get_tightbbox(...)`: signature unchanged. V2 preserves base `None` for invisible axes and preserves visible bbox union behavior.

No public callsite or override signature changes were introduced. No test files were edited.
