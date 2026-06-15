# Baseline Notes

## Root cause

`SQLCompiler.get_combinator_sql()` builds compilers directly from the child
queries stored in `query.combined_queries`. When a combined queryset has an
outer `values()` or `values_list()` selection, the compiler applies that
selection to child queries with `set_values()` if the child query does not
already have a limited selected column list.

That `set_values()` call mutates the original child `Query` objects. A later
evaluation of the same combined queryset with a different `values()` or
`values_list()` selection can then see the stale child `values_select` from the
first evaluation. Since the child now appears to already have selected values,
the compiler does not apply the new outer selection, so the old columns are
returned.

## Files changed

`repo/django/db/models/sql/compiler.py`

The combinator compiler now builds child compilers from cloned child queries.
This preserves the existing SQL generation path while making the compiler-time
`set_values()` adjustment temporary to the compilation being performed. Reusing
or recloning the combined queryset no longer observes selected columns left
behind by a previous evaluation.

`reports/baseline_notes.md`

Added this report to document the root cause, the source change, assumptions,
and rejected alternatives.

## Assumptions and rejected alternatives

I assumed the intended behavior is that applying `values()` or `values_list()`
to a combined queryset should be repeatable and independent across queryset
clones/evaluations, matching normal queryset immutability expectations.

I considered cloning `combined_queries` from `Query.clone()`. That would also
prevent this specific stale state from crossing queryset clones, but it changes
clone semantics for all combined queries and is broader than necessary for the
compiler-side mutation that causes the issue.

I also considered assigning a cloned query only immediately before calling
`set_values()` in `get_combinator_sql()`. Cloning when child compilers are
created is simpler and also protects any other compiler-time mutation of child
queries along this combinator compilation path.
