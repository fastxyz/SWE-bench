# Public Evidence Ledger

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "when comparing float values using the `==` operation, `-0.0` is equal to `0.0`, but their hashcode is different" | Equality and hash semantics must agree for signed zero. | Encoded in `SPEC.md` and K claims. |
| E2 | prompt | Suggested diff uses `Float.compare` in `XYPoint#equals`. | Prefer compare-based equality over hash normalization. | Applied to `XYPoint`; generalized to like classes with same contract bug. |
| E3 | prompt | "A similar issue exists in `TestXYRectangle#testEqualsAndHashCode`, `TestXYCircle#testEqualsAndHashCode`" | Audit the XY geometry equality/hash family, not only one class. | `XYCircle` changed; `XYRectangle` confirmed already aligned. |
| E4 | source | `XYRectangle.equals` uses `Float.compare`; `Rectangle.equals` uses `Double.compare`. | Existing local pattern treats signed zero as distinct for geometry value equality. | Used as the consistency target. |
| E5 | source | `Point`, `Circle`, and `Rectangle2D` used primitive `==` while hashing with `Double.hashCode`/`Objects.hash`. | Same contract violation exists outside V1's changed lines. | Fixed in V2; see F2. |
| E6 | default-domain | Java equal objects must have equal hash codes. | If `equals(a,b)` is true then `a.hashCode() == b.hashCode()`. | Main proof obligation. |
