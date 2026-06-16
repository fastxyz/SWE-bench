# FVK Specification for django__django-17084

Status: constructed, not machine-checked.

## Target

The audited unit is the aggregation wrapping decision inside
`repo/django/db/models/sql/query.py::Query.get_aggregation()`, specifically the
case where an `aggregate()` expression references a selected annotation whose
expression contains a SQL window clause.

The observable property is the generated SQL shape:

- safe shape: the current queryset is wrapped in an inner query, the window
  annotation is selected there, and the outer aggregate references that alias;
- unsafe shape: the outer aggregate directly contains the window expression,
  producing SQL equivalent to `SUM(... OVER (...))`.

## Public Intent Ledger

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| I1 | `benchmark/PROBLEM.md` | The issue reports `aggregate function calls cannot contain window function calls` after aggregating `Sum("cumul_DJR")` where `cumul_DJR` is a `Window(...)` annotation. | `aggregate()` must not compile an aggregate call directly around a selected window annotation. | Encoded by PO1, PO2, PO3. |
| I2 | `benchmark/PROBLEM.md` | The executable example first calls `annotate(cumul_DJR=...)` and then `aggregate(... cumul_DJR_total=Sum("cumul_DJR"))`. | The in-scope window case is a reference to an annotation alias selected by `annotate()`. | Encoded by PO1 and PO3. |
| I3 | `repo/docs/topics/db/aggregation.txt:622` | Aggregates can reference aliases defined by `annotate()`. | Aggregating over annotation aliases is public ORM behavior and must continue to work for window annotations. | Encoded by PO1, PO2, PO3. |
| I4 | `repo/docs/ref/models/expressions.txt:777` | Multiple window expressions in Django ORM are equivalent to expressions in `QuerySet.annotate()` and are selected columns. | A selected window annotation is the natural SQL boundary to aggregate outside of. | Encoded by PO3. |
| I5 | `repo/django/db/models/sql/query.py:455` | Existing wrapping triggers include grouping, slicing, existing aggregation, subquery refs, qualify, distinct, and combinators. | The fix must preserve all existing reasons to wrap and must preserve the direct path when no reason to wrap exists. | Encoded by PO4. |
| I6 | `repo/django/db/models/expressions.py:1206` | `Ref.as_sql()` compiles to the quoted alias name. | In the wrapper path, preserving `Ref("cumul_DJR", ...)` in the outer aggregate produces the safe alias-reference SQL shape. | Encoded by PO3. |

## Formal Model

The formal core is in:

- `fvk/mini-django-query.k`
- `fvk/get-aggregation-spec.k`

The model abstracts `get_aggregation()` to the boolean decision it makes before
choosing the direct query or `AggregateQuery` wrapper. It retains all axes that
can distinguish the reported pass/fail behavior:

- the pre-existing wrap triggers;
- the new `refs_window` trigger;
- the SQL shape difference between an outer aggregate over an alias and a direct
  nested aggregate over a window function.

It intentionally abstracts away model fields, concrete SQL strings, database
connections, result conversion, and expression output fields because those do
not affect whether the forbidden nested aggregate-over-window shape is emitted.

## Contract

For any aggregate expression resolved in `get_aggregation()`:

1. `refs_window` is true if at least one `aggregate.get_refs()` alias names an
   existing selected annotation whose expression has `contains_over_clause`.
2. `get_aggregation()` must use the wrapper path when any previous wrapper
   trigger is true or `refs_window` is true.
3. In the reported case where only `refs_window` is true, the SQL shape must be
   `SafeOuterAlias`: the window annotation is produced by the inner query and the
   outer aggregate references its alias.
4. If no wrapper trigger is true, the direct path may be used.
5. Existing wrapper triggers keep their previous behavior.

## Scope Boundary

The public evidence establishes selected window annotations as in scope. A
direct expression such as `aggregate(total=Sum(Window(...)))` is not specified
by the issue example or the in-repo docs found during the audit. Supporting that
would require a broader expression-lifting rewrite because the current aggregate
wrapper repoints raw columns and preserves selected annotation `Ref`s; it does
not generally hoist arbitrary window-containing expression trees into the inner
query.

This boundary is recorded as Finding F2, not as a reason to change V1.
