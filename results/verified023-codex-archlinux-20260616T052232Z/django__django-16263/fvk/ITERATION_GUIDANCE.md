# FVK Iteration Guidance

Status: V2 source edit applied; no tests or proof tools run.

## Applied in This Iteration

- Addressed Finding F1 by skipping annotation pruning for combined count
  queries.
- Applied the same conservative top-level skip for combined exists queries.

## Keep from V1

- Keep per-annotation alias delta tracking. It is required by F2/PO1/PO4 to
  avoid stale annotation joins changing `COUNT(*)`.
- Keep lookup-reference tracking and annotation dependency tracking. They are
  required by F3/PO2/PO3.
- Keep selected annotations for `distinct()` count and selected non-aggregate
  multi-valued annotations. They are required by F4/PO5.
- Keep the `group_by is True and not annotations` cleanup. It is required by
  PO6 for eligible exists queries.

## Commands for a Real Environment

Do not run these in this benchmark session. In a real environment, run:

```sh
kompile fvk/mini-django-query.k --backend haskell
kast --backend haskell fvk/query-prune-spec.k
kprove fvk/query-prune-spec.k --definition fvk/mini-django-query-kompiled
```

Then run focused Django ORM tests around aggregation, annotation filtering,
exists SQL, distinct count, sliced count, and combinator count.

## Suggested Future Tests

- `Book.objects.annotate(Count("chapters")).count()` should not select the
  unused `Count("chapters")` expression and should equal `Book.objects.count()`.
- `Book.objects.annotate(n=Count("chapters")).filter(n__gt=0).count()` should
  preserve the annotation needed by the filter.
- `Book.objects.annotate(a=..., b=F("a") + 1).filter(b__gt=0).count()` should
  preserve both `b` and its dependency `a`.
- `Person.objects.annotate(full_name=Concat(...)).exists()` should clear the
  unused annotation in the eligible non-combined path.
- `left.annotate(x=...).union(right.annotate(x=...)).count()` should preserve
  combined-query selected-column semantics.

## Residual Risks

- The proof is constructed at an abstract metadata level, not against a full
  executable semantics of Django's SQL compiler.
- The code intentionally favors safety over maximal optimization for
  `distinct()`, compound queries, and multi-valued non-aggregate annotations.
- No runtime behavior was observed in this session.
