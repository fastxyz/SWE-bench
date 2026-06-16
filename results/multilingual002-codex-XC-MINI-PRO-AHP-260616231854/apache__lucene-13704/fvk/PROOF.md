# FVK Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`, tests, Python, or project
code were run.

## Theorem

For doc-values polygon queries using `GeoEncodingUtils.Component2DPredicate`, a point whose encoded
latitude and longitude decode to coordinates contained by the query `Component2D` is not rejected
because of grid-bound round-trip shrinkage. In particular, the issue's point near the north/east
encoded limits is covered by the grid and reaches either a `CELL_INSIDE_QUERY` acceptance or a
`CELL_CROSSES_QUERY` exact `tree.contains` check.

## Proof Sketch

1. `LatLonDocValuesQuery.intersects` extracts encoded `lat` and `lon` directly from sorted numeric
   doc values and calls `component2DPredicate.test(lat, lon)`.
2. `createComponentPredicate` builds the predicate grid by calling `createSubBoxes` with the query
   component's min/max latitude and longitude bounds.
3. In V1, `createSubBoxes` uses conservative lower and upper bound helpers. For each axis:
   - the lower helper starts from raw ceil encoding and decrements while the predecessor's decoded
     coordinate is still inside the lower bound;
   - the upper helper starts from raw floor encoding and increments while the successor's decoded
     coordinate is still inside the upper bound.
4. Therefore, for every encoded coordinate `e` whose decoded value lies in the query interval, the
   conservative encoded interval contains `e`. This discharges PO-2.
5. The issue's values are a direct instance of PO-2. A lower bound at
   `decode(Integer.MAX_VALUE - 3)` cannot exclude an encoded value whose decoded coordinate lies at
   that boundary or above it, and an upper bound at `decode(Integer.MAX_VALUE)` cannot exclude an
   encoded value whose decoded coordinate lies at or below it. This discharges PO-4.
6. Once an encoded point is in the grid, `Component2DPredicate.test` reads the precomputed relation
   for the point's cell:
   - outside returns false;
   - crossing calls exact `tree.contains(decodeLongitude(lon), decodeLatitude(lat))`;
   - inside returns true.
7. By the existing `Component2D.relate` contract, a cell containing a decoded point that is inside
   the component cannot be soundly classified as outside. Therefore the predicate returns true
   through the crossing exact-check or inside path. This discharges PO-1 and PO-3.
8. The helper loops are monotone over a finite `int` domain and guard both endpoints, so they
   terminate. This discharges PO-5.
9. The change adds only private helpers and changes private bound selection inside
   `GeoEncodingUtils.createSubBoxes`; it does not alter public APIs, storage format, query relation
   names, or tests. This discharges PO-6.

## Constructed Symbolic Execution

For the lower latitude helper:

```text
encoded0 = encodeLatitudeCeil(L)
while encoded > Integer.MIN_VALUE and decodeLatitude(encoded - 1) >= L:
    encoded = encoded - 1
return encoded
```

Loop invariant:

```text
encoded <= encoded0
if encoded0 was above the first in-range encoded cell, every decremented-over k had
  decodeLatitude(k) >= L
otherwise encoded0 was already below or equal to the first in-range encoded cell
```

The lower-helper postcondition needed for this issue is conservative coverage, not exact nearest
rounding:

```text
for every e, if decodeLatitude(e) >= L then returnedLower <= e
```

If the raw ceil encoding started too low, the postcondition already holds because the returned
value is a superset lower bound. If it started too high, monotonic decode makes the loop step down
across all still-in-range predecessors until it reaches the first in-range encoded cell.

The longitude lower helper has the same proof shape with `decodeLongitude`. The upper helpers use
the dual postcondition:

```text
for every e, if decodeAxis(e) <= U then e <= returnedUpper
```

If the raw floor encoding started too high, the postcondition already holds because the returned
value is a superset upper bound. If it started too low, monotonic decode makes the loop step up
across all still-in-range successors until it reaches the last in-range encoded cell. These
postconditions prove the returned bounds are safe conservative bounds around the decoded query
interval, subject to Java `int` endpoints.

## Concrete Reproducer Derivation

Let:

```text
a = Integer.MAX_VALUE - 3
b = Integer.MAX_VALUE - 2
c = Integer.MAX_VALUE
```

The query interval on each axis is `[decode(a), decode(c)]`. The stored encoded point produced from
the issue input must decode to a value in that interval for the point to be considered contained
under Lucene's encoded-value semantics. PO-2 gives:

```text
lowerConservative(decode(a)) <= storedEncoded <= upperConservative(decode(c))
```

Thus `test(storedLat, storedLon)` cannot fail at the latitude or longitude grid-range checks. The
cell relation is then consulted. Since the decoded point lies in the rectangle-like polygon, the
cell is not soundly disjoint; it is crossing or inside. Crossing performs exact
`Polygon2D.contains`, and inside accepts.

## Machine-Check Commands Not Run

The following are the commands a full FVK materialization would run. They were not executed in this
session, per task instructions.

```sh
kompile fvk/mini-java-geo.k --backend haskell
kast --backend haskell fvk/geoencodingutils-spec.k
kprove fvk/geoencodingutils-spec.k
```

Expected outcome if the compact model and claims are materialized exactly as described:
`kprove` discharges the helper-bound and predicate-soundness claims to `#Top`, modulo the trusted
`Component2D.relate` soundness assumption stated in `PROOF_OBLIGATIONS.md`.

## Test Guidance

No tests were run and no tests were modified. A test for the issue's reproduced point would be
covered by the constructed proof obligations, but test removal is not recommended because the proof
is not machine-checked and this task forbids changing tests.
