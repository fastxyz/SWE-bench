# Public Compatibility Audit

Status: constructed, not machine-checked.

Changed public symbols:

- `org.apache.lucene.geo.XYPoint.equals(Object)`
- `org.apache.lucene.geo.XYCircle.equals(Object)`
- `org.apache.lucene.geo.Point.equals(Object)`
- `org.apache.lucene.geo.Circle.equals(Object)`

Changed package-private symbol:

- `org.apache.lucene.geo.Rectangle2D.equals(Object)`

Compatibility result:

- No method signatures changed.
- No constructors, field visibility, return types, or hash formulas changed.
- Virtual dispatch shape is unchanged: all methods still override `Object.equals`.
- Behavior changes only for signed-zero-distinct inputs that previously could be
  equal while producing different hash codes. That behavior was the reported defect
  pattern and is not preserved.
- No test files were edited.
