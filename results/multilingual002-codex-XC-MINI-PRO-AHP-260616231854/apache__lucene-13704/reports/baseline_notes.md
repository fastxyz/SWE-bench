# Baseline Notes

## Root Cause

`LatLonDocValuesQuery` uses `GeoEncodingUtils.createComponentPredicate` as the final point match
predicate for `INTERSECTS`, `WITHIN`, and `DISJOINT` relations. That predicate builds a grid over
the query component by converting the component's double latitude/longitude bounds back into
encoded integer coordinates.

For very narrow polygons near the maximum encoded latitude or longitude, those bounds can already
be values returned by `decodeLatitude` or `decodeLongitude`. Re-encoding them with a single
`encodeLatitudeCeil`, `encodeLatitude`, `encodeLongitudeCeil`, or `encodeLongitude` call can round
to the adjacent encoded cell. When that happens, the grid is built one cell too small and rejects a
doc-values point before the exact `Component2D.contains` check can run.

## Files Changed

`repo/lucene/core/src/java/org/apache/lucene/geo/GeoEncodingUtils.java`

The component/distance predicate grid now computes conservative encoded bounds. After the normal
encoding step, the lower-bound helpers step down while the previous decoded cell is still within
the double lower bound, and the upper-bound helpers step up while the next decoded cell is still
within the double upper bound. This keeps the grid inclusive for points that decode exactly onto a
query boundary, including the north/east edge case from the issue, while preserving the existing
grid predicate structure.

## Assumptions and Alternatives

I assumed the intended behavior is based on Lucene's encoded point representation: if an encoded
point decodes to a coordinate inside or on the polygon boundary, the predicate must not reject it
only because of an encode/decode round-trip at the query bound.

I considered changing `LatLonDocValuesQuery` to bypass `Component2DPredicate` and call
`component2D.contains` directly for every point. That would address the reported doc-values
symptom, but it would leave the shared component predicate capable of false negatives and would
discard the existing query acceleration.

I also considered adding a special case only for latitudes close to `90`, but the same boundary
rounding problem can occur for longitude bounds and is better handled in the shared grid-bound
conversion.

No tests were run, in accordance with the task instructions.
