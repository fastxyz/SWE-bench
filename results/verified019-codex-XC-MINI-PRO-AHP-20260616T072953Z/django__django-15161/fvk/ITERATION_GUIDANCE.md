# ITERATION GUIDANCE

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Verdict

V1 stands unchanged. The FVK audit did not surface a source-code defect that
requires a V2 patch.

## Decisions

- Keep the V1 decorators on the root-exported expression classes listed in
  PO-1. This is justified by FINDING F-001 and PO-2.
- Keep constructor and fallback behavior unchanged. This is justified by
  FINDING F-002, PO-3, and PO-4.
- Do not add decorators to `Subquery` or `Exists` in this task. This is
  justified by FINDING F-003 and PO-6.
- Do not modify tests. This follows the benchmark instructions and PO-8.

## Recommended Future Tests

Write focused tests, without changing production behavior further, for:

- `Value`, `Case`, `When`, `ExpressionWrapper`, `OrderBy`, `WindowFrame`,
  `RowRange`, `ValueRange`, `Func`, `ExpressionList`, `Expression`, and
  `OuterRef` exact deconstruction paths.
- Preservation of constructor args and kwargs.
- Subclass fallback paths.
- Migration serialization rendering `models.<ClassName>` from the
  `django.db.models.<ClassName>` path.

## Future Work Boundary

If maintainers later want `Subquery` or `Exists` to be migration-deconstructible,
that should be specified as a separate change. It must define how the embedded
query/queryset argument is serialized, not merely add short-path decorators.

