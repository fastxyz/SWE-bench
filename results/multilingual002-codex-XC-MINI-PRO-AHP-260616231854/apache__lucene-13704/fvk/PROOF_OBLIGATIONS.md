# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Encoded Containment Soundness

For any encoded latitude `latEnc` and longitude `lonEnc`, let:

- `lat = decodeLatitude(latEnc)`
- `lon = decodeLongitude(lonEnc)`
- `T` be the `Component2D` tree passed to `createComponentPredicate`

If `T.contains(lon, lat)` is true, then `Component2DPredicate.test(latEnc, lonEnc)` must return
true.

This obligation captures the public issue's required behavior. It depends on PO-2, PO-3, and PO-4.

## PO-2: Conservative Encoded Bound Coverage

For each coordinate axis with monotone decode function `D`, lower double bound `L`, and upper
double bound `U`, the grid bounds computed by V1 must include every encoded coordinate `e` whose
decoded coordinate lies in the interval:

```text
D(e) >= L and D(e) <= U
  implies
lowerConservative(L) <= e <= upperConservative(U)
```

For latitude this is discharged by `encodeLatitudeCeilConservative` and
`encodeLatitudeConservative`. For longitude this is discharged by
`encodeLongitudeCeilConservative` and `encodeLongitudeConservative`, plus the existing dateline
wrap handling in `createSubBoxes`.

## PO-3: Conservative Bounds Do Not Create False Positives

If PO-2 includes cells that the previous raw encode bounds excluded, those cells must still be
filtered by the existing relation logic:

- `CELL_OUTSIDE_QUERY` returns false;
- `CELL_CROSSES_QUERY` calls exact `tree.contains(decodeLongitude(lon), decodeLatitude(lat))`;
- `CELL_INSIDE_QUERY` may return true only under the `Component2D.relate` contract that the cell
  rectangle is fully inside the component.

This obligation preserves the public API semantics while expanding the candidate grid.

## PO-4: Concrete North-Pole Reproducer Is Covered

For the issue's concrete values:

```text
min = Integer.MAX_VALUE - 3
point = Integer.MAX_VALUE - 2
max = Integer.MAX_VALUE
```

on both latitude and longitude axes, any encoded stored value produced from the point input must be
included by the conservative grid bounds derived from `decode(min)` and `decode(max)`. If
round-trip floating arithmetic moves a raw lower bound one cell too high or a raw upper bound one
cell too low, V1's helper loops recover the boundary cell.

Once the point is inside a grid cell, `Polygon2D.relate` cannot soundly classify that cell as
disjoint from the polygon while the decoded point lies in the polygon. It is therefore inside or
crossing, and the predicate returns true.

## PO-5: Helper Loop Termination

Each conservative helper loop moves monotonically toward a Java `int` endpoint:

- lower-bound helpers decrement `encoded` and stop at `Integer.MIN_VALUE` or the first decoded
  predecessor outside the bound;
- upper-bound helpers increment `encoded` and stop at `Integer.MAX_VALUE` or the first decoded
  successor outside the bound.

The loops are finite over the 32-bit encoded domain. They run once per query grid construction, not
once per indexed point.

## PO-6: Public Compatibility and Scope

The fix must not modify:

- public method signatures;
- field encoding format;
- query relation names or public query APIs;
- test files.

V1 only adds private helper methods and changes private grid-bound selection inside
`GeoEncodingUtils.createSubBoxes`.

## Proof Capability Boundaries

The constructed proof assumes the existing `Component2D.relate` implementations satisfy their
documented relation contract. This is a trusted library obligation outside the V1 diff; the issue
specifically points to component predicate grid rejection, not to polygon point-in-polygon
semantics.
