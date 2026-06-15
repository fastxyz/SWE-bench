# Intent Spec

Status: constructed from public evidence only. No tests, Python, or K tooling were run.

## Required Behavior

I1. `OuterRef()` inside an `exclude()` or negated `Q()` over a many-valued relation must keep pointing at the queryset that enclosed the user's original queryset. In the reported shape, `Item.objects.exclude(tags__category_id=OuterRef('pk'))` inside `Exists()` must resolve `OuterRef('pk')` to `Number.pk`, not to the internal `Item` alias.

I2. The behavior must hold for both public spellings in the issue: `exclude(tags__category_id=OuterRef('pk'))` and `filter(~Q(tags__category_id=OuterRef('pk')))`.

I3. The fix must preserve the existing `split_exclude()` behavior for plain `F()` values. A local `F()` value in the original query is intentionally shifted to the immediate parent query when `split_exclude()` creates its generated nested query.

I4. Values that are neither `OuterRef` nor `F` must remain unchanged by the scope-shifting logic.

I5. The public API and method signatures must remain compatible. The task asks for a source-level bug fix, not an API change.

## Domain

The verified slice is the scope transformation performed by `Query.split_exclude()` when it introduces a generated nested subquery for a negated many-valued relation lookup. The formal model abstracts away full SQL rendering, join trimming, and database execution, but preserves the observable property in the issue: which query level an outer reference binds to after the generated subquery is inserted.

