# FVK Spec: apache__lucene-13704

Status: constructed, not machine-checked. No tests, Python, K tools, or project code were run.

## Scope

The audited production change is V1 in
`repo/lucene/core/src/java/org/apache/lucene/geo/GeoEncodingUtils.java`. The relevant observable is
`LatLonDocValuesField.newSlowPolygonQuery` through `LatLonDocValuesQuery`, which delegates
`INTERSECTS` point matching to `GeoEncodingUtils.Component2DPredicate.test`.

This compact artifact set embeds the FVK intent ledger and adequacy audit here rather than emitting
the larger standalone `INTENT_SPEC.md`, `PUBLIC_EVIDENCE_LEDGER.md`,
`FORMAL_SPEC_ENGLISH.md`, and `SPEC_AUDIT.md` files.

## Public Intent Ledger

| ID | Source | Evidence | Obligation | Status |
|---|---|---|---|---|
| INT-1 | prompt issue | "Narrow polygons close to latitude 90 do not match any points" | A narrow polygon near the maximum latitude must still match contained points. | Encoded in PO-1 and PO-2. |
| INT-2 | prompt issue | "theoretically the point should match" and `assertEquals(1, s.count(query))` | The reproduced point lies in the polygon and the doc-values query must count it. | Encoded in PO-1 and PO-6. |
| INT-3 | prompt issue | "issue is in the component predicate we are using to speed up this queries which reject those points" | The fix should address the shared component predicate path, not merely paper over the doc-values caller. | Encoded in PO-2 through PO-5. |
| INT-4 | public API docs | `LatLonDocValuesField` stores "upper 32 bits ... encoded latitude" and "lower 32 bits ... encoded longitude"; values are indexed with loss of precision. | Query correctness is judged over encoded values and their decoded point coordinates. | Encoded in PO-1 and PO-2. |
| INT-5 | code contract | `Component2D.relate` returns `CELL_OUTSIDE_QUERY`, `CELL_CROSSES_QUERY`, or `CELL_INSIDE_QUERY`; `Component2DPredicate.test` exact-checks `CELL_CROSSES_QUERY`. | A conservative grid may include extra cells only if exact or relation checks prevent false positives. | Encoded in PO-3 and PO-4. |
| INT-6 | task constraint | "Do not modify any test files" and "No execution environment exists" | Source-only reasoning; no tests or tools run; artifacts record commands and expected outcomes only. | Reflected in PROOF.md and FINDINGS.md. |

## Intended Contract

For a `Component2D` query component `T`, `createComponentPredicate(T)` must produce a predicate
that is conservative over Lucene's encoded latitude/longitude space:

1. If an encoded point `(latEnc, lonEnc)` decodes to `(lat, lon)` and `T.contains(lon, lat)` is
true, then `Component2DPredicate.test(latEnc, lonEnc)` must not reject it due to grid bounds.
2. If the grid cell containing `(latEnc, lonEnc)` is classified as crossing, the predicate must use
`T.contains(lon, lat)` as the final answer.
3. If the grid cell is classified as inside, every decoded point in that cell is within `T`.
4. If the grid cell is classified as outside or outside the grid, the decoded point is not within
the query component.

The issue's concrete rectangle-like polygon is an instance:

- `minLat = decodeLatitude(Integer.MAX_VALUE - 3)`
- `maxLat = decodeLatitude(Integer.MAX_VALUE)`
- `minLon = decodeLongitude(Integer.MAX_VALUE - 3)`
- `maxLon = decodeLongitude(Integer.MAX_VALUE)`
- point input uses `decodeLatitude(Integer.MAX_VALUE - 2)` and
  `decodeLongitude(Integer.MAX_VALUE - 2)`

The doc-values query must count that point.

## Candidate Implementation Summary

V1 changes `createSubBoxes` to use conservative encoded bound helpers:

- lower bounds start from `encodeLatitudeCeil` / `encodeLongitudeCeil` and step down while the
  previous decoded cell is still inside the lower bound;
- upper bounds start from `encodeLatitude` / `encodeLongitude` and step up while the next decoded
  cell is still inside the upper bound.

No public method signature, class, field format, query relation semantics, or test file is changed.

## Adequacy Audit

| Formal obligation | Public intent match | Result |
|---|---|---|
| PO-1: contained decoded encoded point must match | Directly matches INT-1, INT-2, and INT-4. | Pass |
| PO-2: conservative encoded bounds include every decoded in-range coordinate | Required by INT-3 because the issue localizes the rejection to component-predicate grid filtering. | Pass |
| PO-3: extra cells cannot create false positives | Required by INT-5 and existing relation/exact-check semantics. | Pass |
| PO-4: concrete issue point remains in grid and reaches relation/exact check | Direct reproduction of INT-2. | Pass |
| PO-5: helper loops terminate and are bounded | Needed for partial-correctness proof to be usable. | Pass |
| PO-6: no API/test compatibility regression | Required by INT-6 and public API preservation. | Pass |

No obligation is derived solely from V1 behavior. The only implementation-derived facts are control
flow facts needed to model the code under audit.

## K-Style Claim Schemas

These claims are written as compact K-style schemas for this benchmark artifact. They are
constructed, not machine-checked.

```k
// SPEC-PROVENANCE: INT-1, INT-2, INT-3, INT-4
claim <k> componentPredicateTest(T, LatEnc, LonEnc) => true </k>
  requires contains(T, decodeLongitude(LonEnc), decodeLatitude(LatEnc))
   andBool inConservativeGrid(T, LatEnc, LonEnc)
   andBool relationSound(T)

// SPEC-PROVENANCE: INT-3, INT-4
claim <k> conservativeLower(D, RawCeil, Bound) => Lower </k>
  ensures forall E . decode(D, E) >=Float Bound impliesBool Lower <=Int E

// SPEC-PROVENANCE: INT-3, INT-4
claim <k> conservativeUpper(D, RawFloor, Bound) => Upper </k>
  ensures forall E . decode(D, E) <=Float Bound impliesBool E <=Int Upper

// SPEC-PROVENANCE: INT-5
claim <k> classifyCell(T, Cell) => inside </k>
  ensures forallDecodedPointsIn(Cell, P => contains(T, P.x, P.y))

// SPEC-PROVENANCE: INT-5
claim <k> classifyCell(T, Cell) => crosses </k>
  ensures componentPredicateUsesExactContains(T, Cell)
```

Expected non-executed commands for a full K materialization:

```sh
kompile fvk/mini-java-geo.k --backend haskell
kast --backend haskell fvk/geoencodingutils-spec.k
kprove fvk/geoencodingutils-spec.k
```
