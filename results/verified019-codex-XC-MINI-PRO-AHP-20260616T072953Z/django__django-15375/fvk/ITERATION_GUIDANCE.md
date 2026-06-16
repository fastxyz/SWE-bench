# Iteration Guidance

Status: V1 stands unchanged.

## Decision

Do not edit production source beyond V1. The FVK obligations show that the current code fixes the reported terminal aggregate path and preserves the non-terminal annotation frame condition.

## Why V1 stands

- F1 and PO1 show the root defect was loss of `is_summary` on the generated `Coalesce`.
- F1 and PO2 show V1 restores the summary marker in the failing `aggregate()` path.
- F2 and PO3 show `coalesce.is_summary = c.is_summary` is preferable to unconditional `True` because it preserves non-terminal annotation semantics.
- F3 and PO4 show no public API compatibility problem.
- F4 and PO5 require honesty about the proof being constructed only; they do not justify a source change.

## Suggested follow-up tests for a normal Django workflow

Do not add tests in this benchmark. In a normal development workflow, add or keep tests for:

- `annotate(...).aggregate(Sum("field", default=0))` on a queryset requiring subquery aggregation;
- the same path where the aggregate does not reference the prior annotation;
- ordinary `annotate(total=Sum("field", default=0))` behavior to confirm it is not treated as a terminal aggregate reduction;
- explicit `Coalesce(Sum("field"), 0)` as a comparison path.

## Machine-check follow-up

When an execution environment is available, run:

```sh
cd fvk
kompile mini-django-aggregate.k --backend haskell
kast --backend haskell aggregate-default-spec.k
kprove aggregate-default-spec.k
```

Keep all tests until the K proof is actually machine-checked.
