# Baseline Notes

## Root cause

`F` had an explicit `@deconstructible(path='django.db.models.F')`
decorator, but the other public expression classes exported from
`django.db.models` relied on the inherited/default deconstruction path. Exact
instances of those classes therefore deconstructed to
`django.db.models.expressions.<ClassName>`, producing more verbose migration
serialization even though the same classes are available as
`django.db.models.<ClassName>`.

## Files changed

`repo/django/db/models/expressions.py`

Added explicit `deconstructible(path='django.db.models.<ClassName>')`
decorators to the public expression classes in this module that already support
deconstruction through `Expression` or `F`: `Expression`, `OuterRef`, `Func`,
`Value`, `ExpressionList`, `ExpressionWrapper`, `When`, `Case`, `OrderBy`,
`Window`, `WindowFrame`, `RowRange`, and `ValueRange`.

This keeps exact-instance deconstruction aligned with the public
`django.db.models` import path while preserving existing fallback behavior for
subclasses and internal expression helper classes.

`reports/baseline_notes.md`

Added this report to document the diagnosis, source change, and scope
decisions for the benchmark.

## Assumptions and rejected alternatives

I treated the public `django.db.models` exports as the safe boundary for
simplified paths, matching the existing `F` behavior described in the issue.

I did not add deconstruction support to `Subquery` or `Exists`. Although they
are exported from `django.db.models`, they do not currently inherit a
`deconstruct()` implementation in this codebase, so making them deconstructible
would be a broader behavior change than simplifying existing expression
deconstruction paths.

I did not change internal-only expression classes such as `CombinedExpression`,
`RawSQL`, `Col`, `Ref`, `Star`, `OrderByList`, `DurationExpression`,
`TemporalSubtraction`, or `ResolvedOuterRef` because they are not exported from
`django.db.models` as direct `models.<ClassName>` imports.

I also avoided changing migration serialization globally or modifying
`django.utils.deconstruct.deconstructible`; the issue can be addressed with
targeted decorators in the expression module.
