# Iteration Guidance

Status: V1 stands unchanged.

## Decision

The FVK audit confirms the V1 source change in
`repo/django/db/models/expressions.py`: keep the `condition_sql == ""` branch in
`When.as_sql()` that renders the full-predicate sentinel as `1=1`.

## Rationale

- Finding F1 is closed by proof obligations O1, O2, and O4.
- Finding F2 confirms that impossible predicates still fall through to the
  default because `EmptyResultSet` behavior was not changed.
- Finding F3 confirms that non-empty predicates and public API compatibility are
  preserved.
- Finding F4 is a verification/tooling limitation, not a source-code defect.

## Next Iteration

When an execution environment is available, run Django's expression/case tests
and add or confirm a regression test for a `Case` with
`When(~Q(pk__in=[]), then=Value(True))`.

When a K environment is available, run:

```sh
kompile fvk/mini-django-case.k --backend haskell
kast --backend haskell fvk/django-case-spec.k
kprove fvk/django-case-spec.k
```

Keep the test suite unchanged until the ordinary test run and any desired K
machine check can be performed.
