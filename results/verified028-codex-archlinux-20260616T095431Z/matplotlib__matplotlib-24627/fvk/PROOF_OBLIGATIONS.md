# FVK Proof Obligations

Status: constructed from public intent and source inspection; not
machine-checked.

The proof is an abstract state proof over the artist parent-bookkeeping state
that the issue observes: `axes`, `figure`, stale callback, and membership in an
axes mouseover set. Rendering, transforms, layout, and numeric plotting data are
outside this issue's observable.

## Suggested Machine-Check Commands

The FVK documentation calls for recording the commands rather than running them
in this environment:

```sh
kompile fvk/mini-matplotlib-clear.k --backend haskell
kast --backend haskell fvk/matplotlib-clear-spec.k
kprove fvk/matplotlib-clear-spec.k
```

These commands were not executed.

## PO-1 - Detachment Helper Postcondition

Claim name: `DETACH-ARTIST-FROM-PARENT`.

Precondition: artist `A` has been removed from the parent-owned container that
made it reachable from an axes or figure.

Postcondition:

- `A.stale_callback is None`.
- If `A.axes` was a settable axes reference, then `A.axes is None`.
- If `A.figure` was non-`None`, then `A.figure is None`.
- If `A` was in the old axes mouseover set, that membership is discarded.
- The helper tolerates artist classes whose `axes` property is read-only.

Discharge argument: `_remove_artist_from_parent()` assigns
`stale_callback = None`, reads `artist.axes` under `try/except`, discards from
`axes._mouseover_set` when present, sets `artist.axes = None` under
`try/except`, and directly assigns `artist.figure = None` when a figure is
present.

Status: discharged by source inspection.

## PO-2 - Axes Clear Coverage

Claim name: `AXES-CLEAR-DEPARTED-ARTISTS`.

Precondition: before `_AxesBase.__clear()` mutates the axes, old artists may be
present in `_children`, `child_axes`, `legend_`, title attributes, and `patch`.

Postcondition:

- Every old artist from `_children` satisfies PO-1.
- Every old child axes object satisfies PO-1.
- The old legend, when present, satisfies PO-1.
- Each old title artist, when present, satisfies PO-1.
- The old patch, when present, satisfies PO-1.
- Retained axis and spine objects are not passed through PO-1 because they are
  reset in place, not deparented.

Discharge argument: V1 snapshots those old containers before mutation, replaces
the clear-owned containers, and calls `_remove_artist_from_parent()` over each
snapshot. The first-clear initialization path is covered by `getattr(..., None)`
and `getattr(..., [])`, so missing attributes are not a counterexample.

Status: discharged by source inspection.

## PO-3 - Figure Clear Coverage

Claim name: `FIGURE-CLEAR-DEPARTED-ARTISTS`.

Precondition: before `FigureBase.clear()` mutates the figure, old artists may
be present in subfigures, axes, and figure-level artist lists.

Postcondition:

- Every old subfigure satisfies PO-1 after it is cleared and removed from
  `subfigs`.
- Every old axes object satisfies PO-1 after it is cleared and removed through
  `delaxes`.
- Every old figure-level artist in `artists`, `lines`, `patches`, `texts`,
  `images`, and `legends` satisfies PO-1 before the list is replaced.

Discharge argument: V1 snapshots `subfigs`, iterates over a tuple snapshot of
`self.axes`, and iterates over a tuple expansion of figure-level artist lists.
Each removed object is passed to `_remove_artist_from_parent()`.

Status: discharged by source inspection.

## PO-4 - No Over-Detachment of Retained Structures

Claim name: `NO-DETACH-RETAINED-AXES-STRUCTURE`.

Precondition: an object is cleared in place and remains reachable from the same
axes after `cla()`.

Postcondition: V1 does not unset that object's parent references merely because
its internal state was reset.

Discharge argument: `_AxesBase.__clear()` still calls `axis.clear()` and
`spine.clear()` in place and does not include axis or spine objects in the
detachment snapshots.

Status: discharged by source inspection.

## PO-5 - Public Compatibility

Claim name: `PUBLIC-COMPATIBILITY`.

Precondition: public callers and subclasses continue to call `clear`, `cla`,
and `clf` with the pre-existing signatures and dispatch shape.

Postcondition: V1 introduces no public signature, return shape, or virtual-call
argument change.

Discharge argument: source diff changes only method bodies and imports a private
helper; all relevant public signatures are unchanged.

Status: discharged by source inspection.

## PO-6 - Honesty Gate

Claim name: `CONSTRUCTED-NOT-MACHINE-CHECKED`.

Precondition: this session forbids running tests, Python, or K tooling.

Postcondition: artifacts must not claim machine-checked proof or recommend test
deletion.

Discharge argument: `PROOF.md` labels the proof constructed, not
machine-checked, and no tests are edited or recommended for deletion.

Status: discharged by artifact inspection.
