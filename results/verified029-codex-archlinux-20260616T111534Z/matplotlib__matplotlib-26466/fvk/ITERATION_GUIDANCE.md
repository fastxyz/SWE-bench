# Iteration Guidance

## Decision

V1 stands unchanged. The FVK audit did not surface a source-code change justified
by the public intent and proof obligations.

## Why No V2 Code Edit

- PO1 directly addresses the reported annotation arrow movement.
- PO2 addresses the public hint about `OffsetFrom`.
- PO3 closes the `AnnotationBbox.xybox` default path that would otherwise
  preserve an alias to the original `xy`.
- PO4 is broader than the issue reproduction but compatible with public stubs
  and the same delayed-use storage pattern.
- PO5 rejects the public hint's `np.array(xy)` form in favor of `tuple(xy)`
  because tuple-style public behavior is evidenced by stubs and tests.

## Follow-Up Tests for a Real Environment

Do not add tests in this benchmark task. In normal Matplotlib development, add
focused tests for:

- `Annotation.xy` independence from a mutated NumPy input array;
- `OffsetFrom._ref_coord` independence from a mutated NumPy input array;
- `AnnotationBbox.xybox` independence for both explicit and default `xybox`;
- optional `ConnectionPatch.xy1` and `xy2` independence if maintainers want the
  broader consistency guarantee.

## Machine-Check Commands

These commands should be run only in an environment with K installed:

```sh
kompile fvk/mini-python.k --backend haskell
kast --backend haskell fvk/annotation-coordinate-spec.k
kprove fvk/annotation-coordinate-spec.k --definition fvk/mini-python-kompiled
```

Expected outcome after any syntax adjustments required by the local K version:
all claims discharge to `#Top`.

## Next Questions if Scope Expands

- Should direct assignment such as `ann.xy = np.array(...)` also snapshot, or is
  it an explicit live assignment by the user?
- Should Matplotlib document coordinate storage as value-snapshot behavior for
  all artists that accept point-like inputs?
- Should non-scalar mutable coordinate elements be rejected or deep-copied? The
  current public contract does not require supporting them.
