# FVK Spec - matplotlib__matplotlib-24627

Status: constructed from public intent and source inspection; not
machine-checked.

## Scope

This FVK pass audits the V1 fix for the issue:

> cla(), clf() should unset the `.axes` and `.figure` attributes of
> deparented artists

The relevant production units are:

- `matplotlib.artist._remove_artist_from_parent`, added by V1.
- `matplotlib.axes._base._AxesBase.__clear`, reached by `Axes.clear()` and
  `Axes.cla()`.
- `matplotlib.figure.FigureBase.clear`, reached by `Figure.clf()` and
  `SubFigure.clear()`.

No tests are in scope for editing, and no execution or K tooling is available.

## Intent Spec

I-1. If `Axes.cla()` / `Axes.clear()` removes a pre-existing artist from the
axes, that artist must no longer report the old axes through `.axes`.

I-2. If `Axes.cla()` / `Axes.clear()` removes a pre-existing artist from the
axes, that artist must no longer report the old figure through `.figure`.

I-3. If `Figure.clf()` / `Figure.clear()` removes artists by clearing child
axes or by replacing figure-level artist lists, those pre-existing deparented
artists must no longer report the old axes or figure.

I-4. Objects reset in place by clear, rather than removed from their parent,
must not be deparented merely because their state is reset. This applies to
axes `Axis` and `Spine` objects.

I-5. The public method signatures and dispatch behavior of `cla()`, `clear()`,
and `clf()` must remain compatible.

## Public Evidence Ledger

E-1. Source: prompt. Quote: "cla(), clf() should unset the `.axes` and
`.figure` attributes of deparented artists." Obligation: postcondition for all
artists deparented by bulk clear. Status: encoded by PO-1, PO-2, and PO-3.

E-2. Source: prompt reproduction. Quote: `l.remove(); print(l.axes)` prints
`None`, while `a.cla(); print(l.axes)` prints the old `Axes(...)`. Obligation:
`cla()` must not leave a stale `.axes` reference on the removed line. Status:
encoded by PO-2 and Finding F-001.

E-3. Source: source code, `Artist.remove()`. Evidence: removal clears
`stale_callback`, discards mouseover membership, sets `.axes = None`, and
directly clears `.figure` for axes-owned artists. Obligation: bulk clear should
perform equivalent parent bookkeeping for artists it removes. Status: encoded
by PO-1.

E-4. Source: source code, `_AxesBase.__clear()`. Evidence: axes clear replaces
`_children`, `child_axes`, `legend_`, title attributes, and `patch`; it clears
axis and spine objects in place. Obligation: detach replaced/removed artists,
but preserve retained axis and spine objects. Status: encoded by PO-2 and
Finding F-003.

E-5. Source: source code, `FigureBase.clear()`. Evidence: figure clear clears
subfigures, clears and removes axes, and replaces figure-level artist lists.
Obligation: detach those pre-existing artists when they are dropped. Status:
encoded by PO-3 and Finding F-002.

E-6. Source: public API compatibility from source. Evidence: V1 does not change
the signatures of `cla`, `clear`, or `clf`; it adds only a private helper.
Obligation: no public callsite or subclass override compatibility break. Status:
encoded by PO-5.

## Formal Spec English

FS-1. For any artist `A` being removed from a parent container by a bulk clear,
calling the private detachment helper leaves `A.stale_callback is None`,
`A.axes is None` when `A` had an axes parent, and `A.figure is None` when `A`
had a figure parent.

FS-2. For any old axes state, `Axes.__clear()` applies FS-1 to every artist in
the old `_children`, every old child axes object, the old axes legend when
present, the old title objects when present, and the old patch when present.
The new axes state may contain replacement titles and a replacement patch, and
retains axis and spine objects.

FS-3. For any old figure state, `FigureBase.clear()` first clears subfigures
and axes, then applies FS-1 to each removed subfigure, each removed axes object,
and each old figure-level artist in `artists`, `lines`, `patches`, `texts`,
`images`, and `legends`.

FS-4. The fix preserves public signatures and method dispatch for `clear`,
`cla`, and `clf`.

## Spec Audit

FS-1 passes: it directly expresses E-1, E-2, and E-3.

FS-2 passes: it covers all pre-existing artist-bearing containers that
`_AxesBase.__clear()` drops or replaces, and it excludes the retained in-place
axis/spine objects as required by I-4.

FS-3 passes: it covers all pre-existing artist-bearing containers that
`FigureBase.clear()` drops or replaces, including axes cleared as part of
`clf()`.

FS-4 passes: source inspection shows no public signature or dispatch-shape
change.

No formal-English obligation is candidate-derived without public or source
support. The proof is still constructed, not machine-checked.

## Public Compatibility Audit

Changed public symbols: none.

Changed private symbols: added `matplotlib.artist._remove_artist_from_parent`.

Public method signatures:

- `_AxesBase.clear(self)` unchanged.
- `_AxesBase.cla(self)` unchanged.
- `FigureBase.clear(self, keep_observers=False)` unchanged.
- `Figure.clf(self, keep_observers=False)` unchanged.

Subclass/override compatibility: V1 does not add parameters to virtual calls.
The existing `clear`/`cla` adapter behavior is unchanged.

Compatibility verdict: pass.
