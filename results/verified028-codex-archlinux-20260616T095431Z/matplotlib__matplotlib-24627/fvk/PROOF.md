# FVK Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, or
`kprove` were run.

## Claims Proved by Construction

The proof discharges the obligations in `PROOF_OBLIGATIONS.md`:

- PO-1: `_remove_artist_from_parent()` clears parent bookkeeping for an already
  deparented artist.
- PO-2: `_AxesBase.__clear()` applies PO-1 to every pre-existing artist it
  deparents.
- PO-3: `FigureBase.clear()` applies PO-1 to every pre-existing artist it
  deparents.
- PO-4: retained axes structures are not over-detached.
- PO-5: public method signatures and dispatch shape remain compatible.
- PO-6: the result is honestly labeled constructed, not machine-checked.

## Abstract State Model

Only the issue-relevant artist state is modeled:

```text
ArtistState = {
    axes: None | AxesRef | read-only axes property,
    figure: None | FigureRef,
    stale_callback: None | Callback,
    mouseover_member: true | false
}
```

Parent containers are modeled as finite lists of `ArtistState` values. A clear
operation has two phases:

1. Snapshot the old parent-owned lists.
2. Replace the parent-owned lists and detach each artist in the snapshots.

This model preserves the observable needed by the issue: whether a user-held
artist still reports a stale `.axes` or `.figure`.

## Proof Sketch

### PO-1: Detachment Helper

Symbolically start with any artist `A` whose parent container has already
dropped it.

Step 1: `_remove_artist_from_parent(A)` assigns `A.stale_callback = None`.

Step 2: the helper reads `A.axes`. If this raises `AttributeError`, the axes
field is read-only and no axes assignment is required for that object. If the
axes value is present, the helper discards `A` from `axes._mouseover_set` when
that set exists, marks the axes stale when supported, and attempts
`A.axes = None`. The assignment either succeeds, proving the target
postcondition, or raises `AttributeError`, which is the read-only case already
allowed by the claim.

Step 3: if `A.figure` is present, the helper assigns `A.figure = None`.

Therefore every settable issue-observed parent field is cleared after the
helper returns.

### PO-2: Axes Clear

At entry to `_AxesBase.__clear()`, V1 snapshots:

- `old_children = list(getattr(self, "_children", []))`
- `old_child_axes = list(getattr(self, "child_axes", []))`
- `old_legend = getattr(self, "legend_", None)`
- old title artists
- `old_patch`

The method then replaces `_children`, `child_axes`, `legend_`, titles, and
`patch` as part of the existing clear operation. For each object in the old
snapshots, V1 calls `_remove_artist_from_parent()`. By PO-1, each object that
was deparented by the list/attribute replacement exits with `.axes` and
`.figure` cleared when those attributes are applicable.

Axis and spine objects are not included in the snapshots. They are reset by
`axis.clear()` and `spine.clear()` and remain reachable from the axes, so PO-4
shows they are not counterexamples to the deparenting postcondition.

### PO-3: Figure Clear

At entry to `FigureBase.clear()`, V1 snapshots subfigures and later iterates
over tuple snapshots of axes and figure-level artist lists. The method performs
the existing structural removals:

- clear each subfigure, replace `subfigs`;
- clear each axes and remove it with `delaxes`;
- replace `artists`, `lines`, `patches`, `texts`, `images`, and `legends`.

Immediately after each removal category, V1 calls
`_remove_artist_from_parent()` on the removed objects. By PO-1, each
pre-existing object deparented by `clf()` exits without stale `.axes` or
`.figure` references.

### PO-5: Compatibility

The public signatures of `clear`, `cla`, and `clf` are unchanged. The only new
callable is private. No virtual call receives a new argument. Therefore public
callers and subclass overrides see the same dispatch shape as before.

## Adequacy Check

The English meaning of the proof matches `SPEC.md`:

- The proof does not certify legacy behavior from the issue's "before" output.
  It uses that output as the defect to eliminate.
- The proof covers both `cla()` and `clf()` paths named in the issue.
- The proof covers `.figure` as well as `.axes`, even though the reproduction
  prints only `.axes`, because the issue title names both attributes.
- The proof excludes retained axis and spine objects because they are not
  deparented by clear.

Adequacy verdict: pass.

## Non-Executed Commands

The commands that would machine-check the abstract K artifacts are:

```sh
kompile fvk/mini-matplotlib-clear.k --backend haskell
kast --backend haskell fvk/matplotlib-clear-spec.k
kprove fvk/matplotlib-clear-spec.k
```

They were not executed in this session.

## Tests

No tests were run and no test files were modified. Because the proof is not
machine-checked, no test-removal recommendation is made.

Tests that would be appropriate in a normal execution environment:

- `Axes.cla()` clears `.axes` and `.figure` on a pre-existing line.
- `Figure.clf()` clears `.axes` and `.figure` on a pre-existing line in an
  axes.
- `Figure.clf()` clears `.figure` on a pre-existing figure-level text artist.
- `Axes.cla()` clears parent references on a pre-existing axes legend.
- `Axes.cla()` does not deparent retained axis/spine objects.

## Residual Risk

This is a partial-correctness proof over a deliberately small model. It does
not prove termination, rendering behavior, layout behavior, or recursive
detachment for auxiliary artists owned internally by compound artists. Those
behaviors are outside the public issue's observable and are not used to justify
the V1 code decision.
