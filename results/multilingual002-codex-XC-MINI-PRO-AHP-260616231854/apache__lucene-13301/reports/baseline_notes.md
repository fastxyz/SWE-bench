# Baseline Notes

## Root Cause

`XYPoint.equals` and `XYCircle.equals` compared `float` fields with `==`. Java treats
`-0.0f == 0.0f` as true, but `Float.hashCode` uses `Float.floatToIntBits`, so signed
zero values produce different hashes. That made distinct hash codes possible for objects
that `equals` considered equal, violating the `equals`/`hashCode` contract.

## Changed Files

- `repo/lucene/core/src/java/org/apache/lucene/geo/XYPoint.java`: changed
  `XYPoint.equals` to compare coordinates with `Float.compare`, matching the semantics
  of `Float.hashCode` for signed zero.
- `repo/lucene/core/src/java/org/apache/lucene/geo/XYCircle.java`: changed
  `XYCircle.equals` to compare center coordinates and radius with `Float.compare`,
  matching the semantics of `Float.hashCode` for signed zero.

## Assumptions and Alternatives

- I assumed signed zero should be treated as a distinct floating-point value for these
  geometry value objects because existing `XYRectangle.equals` already uses
  `Float.compare`, and `XYLine`/`XYPolygon` rely on array equality and hashing that are
  consistent for float bit patterns.
- I considered normalizing hash codes so `-0.0f` and `0.0f` would hash the same while
  keeping `==` equality. I rejected that because it would make `XYPoint` and `XYCircle`
  inconsistent with the already bit-aware `XYRectangle` implementation and with the
  issue's suggested direction.
- I inspected `XYRectangle` because the issue mentioned a similar failure there. No
  source change was needed: it already uses `Float.compare` in `equals` and
  `Float.floatToIntBits` in `hashCode`, so its source-side contract is already aligned.
