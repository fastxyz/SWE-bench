# Baseline Notes

## Root cause

`ContourSet` subclasses `matplotlib.collections.Collection`, whose
`set_paths` method raises `NotImplementedError`.  However, `ContourSet`
already stores and consumes its contour geometry directly through its
`_paths` attribute, and `Collection.get_paths` already returns that same
attribute.  As a result, users could mutate `cs.get_paths()` in place to
replace contour paths, but could not perform the equivalent operation through
the public setter API.

## Files changed

- `repo/lib/matplotlib/contour.py`: Added `ContourSet.set_paths`, assigning
  the provided path sequence to `self._paths` and marking the artist stale.
  This mirrors the existing `PathCollection.set_paths` behavior while keeping
  the change scoped to contour sets.

## Assumptions and alternatives considered

- I assumed `set_paths` should preserve the same semantics as the existing
  workaround `cs.get_paths()[:] = transformed_paths`, namely replacing the
  path sequence used by contour drawing, labeling, and nearest-contour
  calculations.
- I considered changing `Collection.set_paths` to assign `self._paths`
  generically.  I rejected that because several collection subclasses have
  specialized path construction APIs, so changing the base class would broaden
  behavior beyond the reported `ContourSet` issue.
- I did not update tests or run any code, following the benchmark instruction
  that the hidden test suite is fixed and this session has no execution
  environment.
