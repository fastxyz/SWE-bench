# Iteration Guidance

Status: constructed, not machine-checked.

## Code decisions

Keep the V1 compiler strategy:

- metadata ordering is selected only when `query.group_by is None`;
- filtering happens in `get_order_by()`, before `get_extra_select()` and
  `get_group_by()` consume the ordering list.

Apply the V2 introspection alignment:

- `QuerySet.ordered` also uses `query.group_by is None` for the default-ordering
  branch.

## Suggested manual or automated checks

Do not run these in this benchmark session. They are intended commands or test
ideas for a normal development environment.

K machine check:

```sh
kompile fvk/mini-django-compiler.k --backend haskell
kast --backend haskell fvk/django-14122-spec.k
kprove fvk/django-14122-spec.k
```

Django behavioral checks to add or run elsewhere:

- A grouped aggregate query on a model with `Meta.ordering` should not include
  metadata ordering fields in `GROUP BY`.
- The same query with explicit `order_by()` should preserve explicit ordering.
- A non-grouped query should still use `Meta.ordering`.
- `QuerySet.ordered` should be false for a grouped default-ordering-only query,
  including an explicit empty tuple `query.group_by` state if tested at the
  internal `Query` layer.

## Open items

No unresolved code bug remains in the scoped issue. Remaining uncertainty is
only the required honesty caveat: the formal proof and Django behavior were not
executed in this session.
