# Baseline Notes

## Root cause

`Query.get_count()` cloned the original query, added `Count("*")`, and then
delegated to `get_aggregation()`. Any pre-existing annotation remained in
`Query.annotations`, so `get_aggregation()` treated it as an existing annotation
that had to be selected by the inner query. For unused annotations this kept
their SQL expressions, joins, and aggregate-driven grouping in the generated
count query even though the final count result did not depend on the annotation.

`Query.exists()` already clears the select clause in most cases, but grouped
queries created by aggregate annotations could still carry the grouping setup
from annotations that were not used by filters or other required query clauses.

## Changed files

`repo/django/db/models/sql/query.py`

- Added per-annotation bookkeeping for table alias reference-count deltas,
  annotation-to-annotation dependencies, and annotation aliases referenced by
  lookups.
- Replaced the local use of `refs_expression()` in lookup resolution with a
  helper that also records when a filter references an annotation alias.
- Added pruning helpers that remove annotations which are not needed by filters,
  explicit grouping, distinct-on fields, preserved ordering, or required
  annotation dependencies. Removing an annotation also subtracts only the table
  alias reference counts introduced by that annotation.
- Called the pruning helper from `get_count()` before adding `Count("*")`.
- Called the pruning helper from `exists()` when `exists()` is already allowed
  to clear the select clause.

## Assumptions and rejected alternatives

- I assumed selected annotations must be preserved for `distinct()` count
  queries because selected expressions can affect distinct row identity.
- I assumed non-aggregate annotations that introduce multi-valued joins can
  affect row cardinality, so they are preserved unless another clause makes the
  annotation removable.
- I rejected simply masking annotations from `annotation_select`: masking would
  remove them from `SELECT`, but joins introduced while resolving the annotation
  could remain and change `COUNT(*)` results.
- I rejected deleting annotations without reference-count bookkeeping because
  unused many-to-many annotations could leave stale joins behind, while
  annotations used by filters still need their joins.
- I did not run tests or project code, per the task constraints.
