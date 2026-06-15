# Formal Spec English

This is the English paraphrase of the K claims in
`fvk/django-11265-spec.k`. The claims are constructed, not machine-checked.

## CLAIM-SPLIT-EXCLUDE-COPIES-FILTERED-RELATIONS

For any `split_exclude()` call whose filter left-hand side begins with a
filtered relation alias present in the outer query, the generated inner query
has the same filtered relation mapping before `add_filter()` resolves the
lookup. Therefore lookup resolution succeeds for that alias instead of raising
the reported `FieldError`.

## CLAIM-TRIM-MOVES-FILTERED-CONDITION

If `trim_start()` is about to trim the first inner join, and that join carries
a non-empty filtered relation condition whose resolved column aliases do not
include aliases being trimmed away, the condition is added to the inner query
`WHERE` clause before the join is trimmed. The resulting subquery selects the
same parent keys as the original filtered join.

## CLAIM-TRIM-KEEPS-PARENT-ALIAS-CONDITION

If the filtered relation condition refers to an alias that would be removed by
the first-join trim, `trim_start()` does not perform that first trim. The
filtered join remains a join, so the condition remains attached to the `ON`
clause with all aliases it needs.

## CLAIM-UNFILTERED-FRAME

If the first join has no filtered relation, or if there is no filtered relation
alias in the filter expression, the previous `split_exclude()` and
`trim_start()` behavior is unchanged.

## CLAIM-EXCLUDE-SEMANTICS

For the public issue shape, `exclude(filtered_alias__lookup=value)` keeps an
outer object exactly when there is no related row satisfying both the
`FilteredRelation.condition` and the lookup predicate.

