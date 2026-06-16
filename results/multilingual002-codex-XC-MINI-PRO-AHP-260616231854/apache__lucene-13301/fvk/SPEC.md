# FVK Spec

Status: constructed, not machine-checked.

## Scope

This FVK pass verifies the equality/hash contract for the geometry value classes
affected by signed-zero-sensitive hashes:

- `XYPoint`
- `XYCircle`
- `XYRectangle`
- `Point`
- `Circle`
- `Rectangle2D`

`XYLine`, `XYPolygon`, `Line`, and `Polygon` use array equality/hash helpers whose
floating-point element semantics are already bit-aware. Numeric geometry predicates
such as `Point2D.contains` are outside this equality/hash contract.

## Public Intent Ledger

| ID | Evidence | Spec obligation |
| --- | --- | --- |
| I1 | Problem statement says primitive `==` treats `-0.0` and `0.0` as equal while hash codes differ. | Equality must not return true for signed-zero-distinct values while hash remains signed-zero-sensitive. |
| I2 | Problem statement suggests `Float.compare` for `XYPoint#equals`. | Use compare-based equality rather than normalizing hash codes. |
| I3 | Problem statement says similar issue exists for `XYRectangle` and `XYCircle`. | Audit the XY geometry equality/hash family. |
| I4 | Existing `XYRectangle.equals` and `Rectangle.equals` use `Float.compare`/`Double.compare`. | Preserve the local compare-based convention. |
| I5 | Java default contract for value objects. | If `a.equals(b)` then `a.hashCode() == b.hashCode()`. |

## Domain

The proof domain is constructed geometry objects whose coordinate fields satisfy
their constructors' validation rules:

- XY coordinates are finite `float` values accepted by `XYEncodingUtils.checkVal`.
- latitude/longitude values are accepted by `GeoUtils` validation.
- radii are finite and satisfy the class-specific radius guard.
- NaN and infinities are outside the in-domain equality/hash proof because the
  constructors reject them for these value objects.

## Contract

For each audited class, equality over same-class objects is the conjunction of
field-wise `Float.compare(...) == 0` or `Double.compare(...) == 0`, matching the
field type. Hash code formulas remain unchanged. The required postcondition is:

```text
same-class(a, b) and a.equals(b) implies a.hashCode() == b.hashCode()
```

The signed-zero discriminator is:

```text
field(a) = -0.0 and corresponding field(b) = +0.0 implies a.equals(b) == false
```

## Formal Model

The K model in `fvk/mini-java-float-equality.k` represents each finite float or
double as its hash-relevant canonical bit key. This abstraction keeps the property
axis under verification: `-0.0` and `+0.0` map to different keys, while identical
hash-relevant values map to the same key. The claims in `fvk/geo-equality-spec.k`
state that compare-based equality implies equal hashes for each audited class and
that signed-zero-distinct values are not equal.
