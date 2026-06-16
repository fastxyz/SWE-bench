# Public Compatibility Audit

## Changed Public or Semi-Public Storage

| Symbol | Change | Public compatibility result |
| --- | --- | --- |
| `_AnnotationBase.xy` / `Annotation.xy` | Stores `tuple(xy)` instead of the caller object. | Compatible with docs and stubs exposing `(float, float)` / `tuple[float, float]`; indexing, unpacking, and tuple equality remain valid. Direct in-place mutation of an input array no longer updates the annotation, which is the intended bug fix. |
| `OffsetFrom._ref_coord` | Stores `tuple(ref_coord)` instead of the caller object. | `_ref_coord` is private; public `OffsetFrom` behavior still accepts the same coordinate inputs and computes from the construction-time point. |
| `AnnotationBbox.xybox` | Stores `tuple(xybox)` when explicit; defaults to copied `self.xy` when omitted. | Compatible with docs and stubs typing `xybox` as a tuple coordinate. The documented default `xybox=xy` is preserved by value. |
| `ConnectionPatch.xy1` / `xy2` | Stores `tuple(xyA)` and `tuple(xyB)` instead of caller objects. | Compatible with stubs typing both attributes as tuples; public indexing and string formatting still work. |

## Signatures and Dispatch

- No function or method signatures changed.
- No new keyword arguments or virtual dispatch calls were introduced.
- No public subclass override must be updated.
- No producer/consumer protocol changed: rendering code still consumes
  two-coordinate indexable values.

## Compatibility Risks Considered

- Converting all stored coordinates to `np.array(...)` was rejected because
  public tests compare `.xy` to tuples and NumPy array equality would produce an
  array-valued comparison.
- Users who intentionally relied on mutating the original input array to move an
  annotation lose that behavior. The issue identifies that live linkage as the
  bug, and the public API documents coordinates as values rather than live
  references.
