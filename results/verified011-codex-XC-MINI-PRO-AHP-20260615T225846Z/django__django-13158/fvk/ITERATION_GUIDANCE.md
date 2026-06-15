# Iteration Guidance

Status: constructed, not machine-checked.

## Applied in V2

Move the empty-query guard from `get_combinator_sql()` to `SQLCompiler.as_sql()`
before the combined-query backend support check. This is justified by F-02 and
PO-03. The resulting source diff is still minimal and limited to
`repo/django/db/models/sql/compiler.py`.

## Decisions Not to Change

Do not add a form-layer workaround. F-03 and PO-05 show that the form code is
already using the documented empty-value producer, so changing forms would
duplicate the ORM contract rather than fix the root cause.

Do not clear `query.combinator` or `query.combined_queries` in `Query.set_empty()`
for this task. F-04 records that public evidence proves result-access behavior
for `.none()`, but does not require changing the supported operation matrix for
querysets derived from combined queries.

Do not edit tests. PO-08 and the benchmark instructions prohibit test changes.

## Suggested Human Follow-Up

Machine-check the constructed proof when a K environment is available:

```sh
kompile fvk/mini-django-query.k --backend haskell
kast --backend haskell fvk/django-query-none-spec.k
kprove fvk/django-query-none-spec.k
```

Keep or add conventional tests until the K proof is actually machine-checked.
Useful public test shapes are:

- `qs.union(other).none()` evaluates to an empty list;
- `qs.union(other).none().count()` is zero;
- optional `ModelMultipleChoiceField` with an empty submitted value and a
  `union()` queryset saves no related objects.
