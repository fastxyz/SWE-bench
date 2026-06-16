# Intent Spec

Status: constructed, not machine-checked.

1. The reported bug is an `equals`/`hashCode` contract failure for floating-point
   geometry value objects when signed zero is involved.
2. For geometry classes whose hashes use `Float.hashCode`, `Double.hashCode`,
   `Float.floatToIntBits`, or boxed `Double` hashing, equality must use the same
   signed-zero-sensitive equivalence relation.
3. `-0.0f` and `0.0f` must not be considered equal by these value-object `equals`
   methods unless their hash code computation is also changed to normalize signed
   zero. This audit chooses compare-based equality because `XYRectangle` and
   `Rectangle` already use `Float.compare`/`Double.compare`.
4. Constructors, validation rules, public method signatures, and hash formulas are
   frame conditions: the fix should not alter them.
5. Public or in-repo equality tests that decide expected equality using primitive
   `==`/`!=` for floats or doubles are suspect for this issue because that is the
   behavior the issue identifies as the bug source.
