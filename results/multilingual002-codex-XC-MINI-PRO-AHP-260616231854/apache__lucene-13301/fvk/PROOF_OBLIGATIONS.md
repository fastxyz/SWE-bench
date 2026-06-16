# Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Public Intent and Domain

For all in-domain constructed instances of the audited geometry classes, `equals`
and `hashCode` must satisfy the Java value-object contract. In-domain fields are
finite and constructor-accepted; NaN and infinities are outside this proof domain.

## PO-2: Signed-Zero Discriminator

The formal model must distinguish `-0.0` from `+0.0`, because this is the concrete
failure family in the issue. A model that collapses signed zero would be inadequate.

## PO-3: Reported XY Classes

`XYPoint.equals` and `XYCircle.equals` must use field-wise `Float.compare` semantics.
If equality is true, the unchanged `Float.hashCode`-based hash formula must compute
the same hash for both objects.

## PO-4: Adjacent Double-Valued Classes

`Point.equals`, `Circle.equals`, and `Rectangle2D.equals` must use field-wise
`Double.compare` semantics. If equality is true, the unchanged `Double.hashCode` or
`Objects.hash` formula must compute the same hash for both objects.

## PO-5: Local Consistency With Existing Geometry Classes

The repair must align with existing compare-based classes (`XYRectangle` and
`Rectangle`) rather than introducing a second convention that normalizes signed zero
only in some classes.

## PO-6: Confirmed-Unchanged Classes

`XYRectangle` must remain unchanged because it already satisfies PO-2 and PO-3.
Array-backed geometry classes are out of scope when their array equality and hashing
already use bit-aware floating-point element semantics.

## PO-7: Compatibility and Test Constraints

The fix must not change method signatures, constructors, hash formulas, or test files.
Public tests that encode primitive `==` as the expected equality relation are suspect
for this issue and must not override the intent spec.

## PO-8: FVK Honesty Gate

Because this environment forbids execution, K commands and tests must not be run.
The proof must be labeled constructed, not machine-checked, and no test deletion may
be recommended unconditionally.
