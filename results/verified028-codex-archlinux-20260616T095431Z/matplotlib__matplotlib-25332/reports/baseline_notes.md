## Root cause

`Figure.align_labels()` calls `align_xlabels()` and `align_ylabels()`, which store aligned Axes relationships in `FigureBase._align_label_groups`. Those groups are `matplotlib.cbook.Grouper` instances.

`Grouper` stores its membership graph as `weakref.ref` keys and values. Python cannot pickle `weakref.ReferenceType` objects, so once label alignment populates the groupers, pickling a figure reaches those weakrefs and raises `TypeError: cannot pickle 'weakref.ReferenceType' object`.

## Changed files

`repo/lib/matplotlib/cbook.py`

Added `Grouper.__getstate__` and `Grouper.__setstate__`. The pickle state is now the live disjoint groups returned by `Grouper.__iter__`, represented as ordinary object lists. On unpickle, the grouper starts with an empty weakref mapping and rejoins each saved group, recreating the weakrefs from the restored objects.

This keeps the fix at the weakref container that causes the pickle failure, and it preserves alignment relationships instead of dropping them from the figure state.

## Assumptions and rejected alternatives

I assumed the intended behavior is not only that `pickle.dumps(fig)` succeeds after `align_labels()`, but also that the alignment groups remain available when the figure is unpickled and drawn again.

I considered special-casing `Figure.__getstate__` to omit `_align_label_groups`. That would make pickling succeed, but it would silently lose the persistent alignment state documented by `align_xlabels()` and `align_ylabels()`.

I also considered adding figure-specific serialization of `_align_label_groups`. That would work for this one path, but `Grouper` itself is the object with unpickleable internals, and making it pickle-aware matches the existing behavior of serializing axes sharing relationships as concrete sibling objects before rebuilding weakref groups.

No tests or project code were run, per the task constraints.
