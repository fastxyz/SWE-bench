# Iteration Guidance

Status: constructed, not machine-checked.

## Code decision

Keep V1 unchanged.

Rationale:

- F-001 identifies the bug as shared component `Query` objects across derived
  combined querysets.
- PO-1 through PO-4 are discharged by cloning `combined_queries` in
  `Query.clone()`.
- F-002 records that changing `_combinator_query()` was considered but is not
  required by the public intent or the proof obligations.
- PO-5 confirms compatibility is preserved.

## Suggested future tests

Do not add tests in this task. For a normal development environment, add a
regression test shaped like:

```python
qs = Model.objects.filter(...).union(
    Model.objects.filter(...),
).order_by('order')
list(qs[:REPR_OUTPUT_SIZE + 1])
list(qs.order_by().values_list('pk', flat=True))
list(qs[:REPR_OUTPUT_SIZE + 1])
```

The expected result is that the last evaluation does not raise an error about
the order-by position missing from the select list.

## Machine-check next step

In an environment with K installed, run:

```sh
kompile fvk/mini-query-clone.k --backend haskell
kast --backend haskell fvk/query-clone-spec.k
kprove fvk/query-clone-spec.k
```

Keep all tests until `kprove` returns `#Top`.

## If future evidence contradicts V1

If a future public report shows mutation during set-operation construction
itself, promote cloning in `QuerySet._combinator_query()` to a new proof
hypothesis. That is not required for this issue because the reported breakage is
introduced by deriving from an existing ordered union.
