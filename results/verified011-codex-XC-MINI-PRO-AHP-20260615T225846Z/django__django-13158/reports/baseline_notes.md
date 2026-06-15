# Baseline Notes

## Root cause

`QuerySet.none()` marks a queryset empty by adding a `NothingNode` to the
outer `Query.where`. For combined querysets such as those produced by
`union()`, SQL generation is delegated to `SQLCompiler.get_combinator_sql()`,
which builds SQL from `query.combined_queries`. That path skipped empty child
queries, but it did not check whether the combined query itself had been marked
empty. As a result, calling `.none()` on a combined queryset left the original
union operands in place and the compiler returned SQL for those operands instead
of raising `EmptyResultSet`.

In the reported form path, `ModelMultipleChoiceField.clean()` returns
`self.queryset.none()` for an optional empty submission. When the field queryset
was a `union()`, that supposedly empty queryset still evaluated to all rows
from the union.

## Changed files

`repo/django/db/models/sql/compiler.py`

Added an early `self.query.is_empty()` check in
`SQLCompiler.get_combinator_sql()`. If the outer combined query has already
been marked empty, the compiler now raises `EmptyResultSet` before assembling
SQL from the stored combined operands. Existing compiler execution paths already
translate `EmptyResultSet` into an empty result iterator or no result for count
and existence checks.

## Assumptions and alternatives considered

I assumed the correct fix belongs in ORM SQL compilation because the form code
is already asking the queryset for `.none()`, and non-combined querysets already
handle that marker correctly.

I considered changing `ModelMultipleChoiceField.clean()` to special-case empty
combined querysets, but rejected that because the issue is not form-specific:
any `.none()` call on a combined queryset can evaluate incorrectly.

I also considered clearing `query.combinator` and `query.combined_queries` from
`Query.set_empty()`. I rejected that broader state mutation because the minimal
bug is that the compiler ignores the outer empty marker for combined queries;
honoring that marker in the combined SQL path fixes the behavior without
changing queryset state or the set of operations Django considers combined.

No tests or project code were run, per task constraints.
