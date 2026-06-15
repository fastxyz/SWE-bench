# Iteration Guidance

Status: V1 stands unchanged.

## Decision

No additional production-code edit is justified by the FVK audit. The V1 change
is the minimal source edit that discharges PO-001 and PO-002 while preserving
PO-003, PO-005, and PO-006.

## If another iteration were allowed

Keep the source fix as-is.

Add tests, if test edits were allowed, for:

- mixed `OR`/`AND` `CheckConstraint` SQL on SQLite-style table rebuilds;
- the same nested `Q` shape on any backend whose check-constraint syntax rejects
  table-qualified column references;
- an expression-valued lookup inside a nested schema predicate, to cover PO-004.

After a real K environment is available, run:

```sh
kompile fvk/mini-django-query.k --backend haskell
kast --backend haskell fvk/django-query-spec.k
kprove fvk/django-query-spec.k
```

Keep all tests until the proof is machine-checked.
