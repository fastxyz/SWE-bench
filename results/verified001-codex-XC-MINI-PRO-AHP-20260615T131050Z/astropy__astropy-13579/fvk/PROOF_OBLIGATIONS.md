# Proof Obligations

Status: constructed, not machine-checked.

## O1: Valid Sliced-WCS Domain

Inputs must satisfy `validSlicedWCS(W, S, PK, WK)`: slices are sanitized,
`PK` and `WK` are non-empty, and axis sets match the wrapper's `_pixel_keep` and
`_world_keep` construction.

Status: discharged by existing constructor logic and retained unchanged.

## O2: Fixed Dropped World Coordinates

For dropped world axes, the value inserted into the full world vector must be:

```
p2w(W, expandPixelsAtSlicedZero(S))[dropped_axis]
```

Status: discharged by V2 source lines
`_world_values_at_sliced_pixel()` and the dropped-axis branch of
`world_to_pixel_values`.

## O3: Dropped World Independence

If a world axis is not in `WK`, the existing correlation-matrix contract says it
does not depend on kept pixel axes. Therefore:

```
mergeKeptAndDroppedWorlds(
  WK,
  selectKeptWorlds(p2w(W, expandPixels(S, P)), WK),
  p2w(W, expandPixelsAtSlicedZero(S)))
==
p2w(W, expandPixels(S, P))
```

Status: domain side condition. This is the key mathematical obligation that
licenses evaluating dropped values at sliced pixel zero.

## O4: Wrapped WCS Inverse

For full pixel vectors on the slice, the wrapped WCS inverse satisfies:

```
w2p(W, p2w(W, expandPixels(S, P))) == expandPixels(S, P)
```

Status: assumed from the low-level WCS inverse contract and the issue's full-WCS
reference behavior. The wrapper proof does not prove wcslib.

## O5: Slice Start Adjustment And Kept Pixel Projection

After the wrapped inverse returns a full pixel vector, range-slice starts are
subtracted and `_pixel_keep` components are returned:

```
selectKeptPixels(adjustForSliceStarts(expandPixels(S, P), S), PK) == P
```

Status: discharged by existing code retained in `world_to_pixel_values`.

## O6: API/Shape Frame

The fix must preserve method signatures, world input order, pixel output order,
broadcasting through `np.broadcast_arrays`, and one-dimensional return
conventions.

Status: discharged by unchanged public signatures and unchanged surrounding
code. NumPy broadcasting itself is outside the abstract proof.

## O7: No Added Stale Transform Cache

The inverse transform should not introduce a new cached fixed-world vector that
can outlive the current wrapped-WCS state.

Status: V1 partially violated this by using a lazy cached helper in the
transform path. V2 discharges it by making `_world_values_at_sliced_pixel` a
regular method and computing it per `world_to_pixel_values` call when needed.
