# FVK Iteration Guidance

Status: V1 stands unchanged.

## Decision

No source edit is required beyond the V1 change in
`repo/django/db/models/sql/query.py`.

Reasoning:

- F-001 is resolved by PO-001 through PO-003.
- F-002 discharges the only structural concern about `.target` availability.
- F-003 confirms the frame condition for annotation-only and same-field cases.
- F-004 is a process limitation, not a source-code defect.

## Recommended Follow-Up Tests

Do not edit tests in this benchmark session. In a normal Django development
environment, add or keep public tests covering:

1. Nested `Subquery()` annotation filtered with a `SimpleLazyObject` wrapping a
   related model instance.
2. A simpler single-level `Subquery()` over `values("<foreign-key>")` filtered
   by a lazy related model instance.
3. A non-relational single-column subquery to confirm `target == field` frame
   behavior.
4. Annotation-only subquery output-field resolution to confirm the unchanged
   branch.

## Machine-Check Follow-Up

If K tooling is available later, run:

```sh
kompile fvk/mini-django-query.k --backend haskell
kast --backend haskell fvk/query-output-field-spec.k
kprove fvk/query-output-field-spec.k
```

Expected result: `kprove` returns `#Top` for the constructed claims. Until that
happens, keep the proof labeled constructed, not machine-checked.
