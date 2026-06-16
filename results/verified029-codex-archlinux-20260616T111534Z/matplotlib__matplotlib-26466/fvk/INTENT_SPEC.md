# Intent Specification

This specification is intent-first. Current V1 behavior is treated as the
candidate implementation to audit, not as the source of expected behavior.

## Required Behaviors

1. `Annotation` construction must snapshot the coordinate values passed as
   `xy`. If the caller later mutates a NumPy array used as `xy`, the annotated
   endpoint and any arrow ending at that point must still use the original
   coordinate values.

2. The in-scope coordinate domain is a point-like iterable of exactly two scalar
   coordinate values. This is derived from the documented `(float, float)` API
   and the type stubs. Mutable objects contained inside the coordinate elements
   themselves are outside this scalar-coordinate domain.

3. Public tuple-like behavior of coordinate attributes must be preserved:
   indexing, unpacking, and equality with `(x, y)` tuples remain valid. This is
   supported by the public type stubs and public tests that compare annotation
   coordinates to tuples.

4. `OffsetFrom` must snapshot `ref_coord` for the same delayed-use reason as
   `Annotation.xy`: it stores a coordinate pair and later reads it to compute a
   transform.

5. `AnnotationBbox` must snapshot its annotated point through
   `_AnnotationBase`; when `xybox` is provided explicitly, it must also snapshot
   that coordinate pair; when omitted, `xybox` must default to the already
   snapshotted `xy` value.

6. `ConnectionPatch` endpoint attributes `xy1` and `xy2` are documented and
   typed as coordinate tuples. Snapshotting the endpoint values is compatible
   with that public contract and avoids the same delayed-use aliasing pattern.

## Out of Scope

- Full rendering, transforms, clipping, and unit conversion. The reported bug is
  the stored reference to caller-owned mutable coordinates; once the stored
  value is independent, the existing rendering path reads the intended point.
- Direct user assignment after construction, such as `ann.xy = arr`. The issue
  concerns arrays passed to constructors and `Axes.annotate`.
- Running tests, Python, or K tooling in this environment.
