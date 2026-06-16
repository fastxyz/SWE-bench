# Baseline Notes

## Root cause

`_AnnotationBase.__init__` stored the `xy` argument by reference. When callers
passed a mutable object such as a NumPy array, later mutations of that object
changed `self.xy`, so annotation drawing recomputed arrow endpoints from the
mutated coordinates.

The same delayed-use pattern existed in nearby annotation coordinate helpers:
`OffsetFrom` retained `ref_coord`, `AnnotationBbox` retained `xybox`, and
`ConnectionPatch` retained its endpoint coordinates. These values are all read
later during drawing, so storing caller-owned mutable sequences can make artists
move after construction without an explicit Matplotlib update.

## Files changed

- `repo/lib/matplotlib/text.py`
  - `_AnnotationBase.__init__` now stores `xy` as `tuple(xy)`, detaching the
    annotation point from mutable caller input while preserving tuple-like public
    behavior.
  - `OffsetFrom.__init__` now stores `ref_coord` as `tuple(ref_coord)` for the
    same reason.

- `repo/lib/matplotlib/offsetbox.py`
  - `AnnotationBbox.__init__` now stores explicit `xybox` values as tuples and,
    when `xybox` is omitted, defaults to `self.xy` instead of the original
    caller-provided `xy` object.

- `repo/lib/matplotlib/patches.py`
  - `ConnectionPatch.__init__` now stores `xyA` and `xyB` as tuples so its
    delayed endpoint computation is not affected by later mutations of caller
    arrays.

## Assumptions and alternatives considered

- I assumed annotation point inputs are point-like iterables of length two, as
  documented by the public APIs and reflected in the type stubs.
- I used `tuple(...)` instead of `np.array(...)` because existing public
  attributes and type stubs expose these coordinates as tuples, and tuple
  equality keeps existing tuple-based assertions working. Converting all inputs
  to NumPy arrays would detach mutable input but would change comparisons such
  as `ann.xy == (x, y)` into array-valued comparisons.
- I did not change generic patch vertex storage such as polygon `xy`, where
  mutable array-like state is broader API surface and outside the annotation
  coordinate bug.
- I did not add or modify tests because the benchmark instructions forbid
  modifying test files and running code.
