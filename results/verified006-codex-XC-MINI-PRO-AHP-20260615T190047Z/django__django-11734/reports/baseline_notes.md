# Baseline Notes

## Root cause

`Query.split_exclude()` rewrites negated filters across many-valued joins into an extra nested subquery. It already compensates for that extra nesting for plain `F()` values by wrapping them in `OuterRef()`, so a value that originally belonged to the parent query is still resolved against that parent after the rewrite.

`OuterRef()` values also need that one-level scope shift. Before this change, `OuterRef('pk')` was treated by the generic `F` branch as `OuterRef(filter_rhs.name)`, which produced another `OuterRef('pk')` instead of `OuterRef(OuterRef('pk'))`. The generated split-exclude subquery then resolved that reference against its immediate parent query, such as the `Item` query inside `Exists()`, instead of preserving it for the real outer query, such as `Number`. That caused SQL to compare against the wrong alias/model.

## Changed files

`repo/django/db/models/sql/query.py`

Changed `Query.split_exclude()` to special-case `OuterRef` before the broader `F` check. Existing `OuterRef` instances are now wrapped as `OuterRef(filter_rhs)`, preserving one additional outer-query level when `split_exclude()` introduces its generated subquery. The existing behavior for plain `F()` expressions is unchanged.

## Assumptions and alternatives considered

I assumed the intended behavior is that an `OuterRef()` in the user's original queryset keeps the same semantic target after Django internally rewrites an `exclude()` or negated `Q()` across a many-valued relation. This matches the existing `F()` handling in `split_exclude()`, which already shifts local references outward for the generated subquery.

I considered changing `Query.resolve_expression()` or lookup resolution so nested `IN` subqueries would resolve outer references against a different query. I rejected that because it would affect all subquery resolution paths and risk changing valid nested subquery behavior. The bug is localized to `split_exclude()` adding a new nesting level without adjusting existing `OuterRef` values.

I also considered changing `OuterRef.resolve_expression()` itself, but rejected that because nested `OuterRef(OuterRef(...))` is already the mechanism Django uses to represent references beyond the immediate parent query. The fix should create the correct nested `OuterRef` shape at the point where Django introduces the additional subquery.

Per the task instructions, I did not run tests or project code.
