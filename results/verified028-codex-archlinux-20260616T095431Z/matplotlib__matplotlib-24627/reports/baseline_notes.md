# Baseline Notes

## Root Cause

`Artist.remove()` clears an artist's parent bookkeeping after removing it from
its parent container: the stale callback is cleared, the artist is removed from
the axes mouseover set, and its `axes` and `figure` references are unset.

`Axes.__clear()` and `FigureBase.clear()` did not go through that bookkeeping.
They replaced lists such as `Axes._children`, `Axes.child_axes`,
`FigureBase.artists`, `FigureBase.texts`, and related containers with new empty
lists. Artists that had been deparented by `cla()` or `clf()` therefore kept
stale `axes` and/or `figure` references even though they were no longer
reachable from the cleared axes or figure.

## Changed Files

`repo/lib/matplotlib/artist.py`

Added the private helper `_remove_artist_from_parent()`. It centralizes the
low-level parent bookkeeping needed when an artist has already been removed
from its parent container by bulk operations rather than by `Artist.remove()`.
The helper clears stale callbacks, discards the artist from an axes mouseover
set when applicable, and unsets `axes` and `figure` references while tolerating
artist classes with read-only `axes` properties.

`repo/lib/matplotlib/axes/_base.py`

Updated `_AxesBase.__clear()` to snapshot the artists that are about to be
deparented, then clear their parent bookkeeping after replacing the axes child
lists. This covers normal child artists, child axes, axes legends, replaced
title artists, and the replaced axes patch. Retained objects such as axis and
spine instances are still cleared in place and are not deparented.

`repo/lib/matplotlib/figure.py`

Updated `FigureBase.clear()` so `clf()` clears parent bookkeeping for
deparented subfigures, axes, and figure-level artists before replacing the
figure-level artist lists. This makes figure clearing consistent with the
state transition expected after removing an artist from its parent.

## Assumptions and Alternatives

I treated "deparented artists" as the artists that `cla()` or `clf()` already
remove from their parent-owned containers. I did not detach retained structural
objects such as axes' `Axis` and `Spine` instances because `Axes.__clear()`
resets those objects in place rather than replacing them.

I included replaced axes titles and patches because `Axes.__clear()` creates
new instances for those attributes, so any user-held references to the old
objects are deparented by the clear operation.

I considered calling `remove()` on each artist during clear, but rejected that
because clear has already started replacing parent containers and `remove()`
depends on each artist's `_remove_method` still matching the active parent
list. A direct bookkeeping helper is narrower and avoids re-entering parent
container mutation during bulk clears.

I did not modify tests or run tests/code, per the task constraints.
