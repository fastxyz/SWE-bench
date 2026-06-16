# FVK Iteration Guidance

Status: constructed, not machine-checked.

## Code Decision

V1 stands unchanged after FVK audit.

Rationale:

- F1 and PO1/PO3 show the reported `values().annotate()` crash path is addressed.
- F2 and PO2/PO3 show the public `values_list()` concern is addressed for tuple, flat, and named modes.
- F3 and PO4 show V1 improved on the public hint by using `has_select_fields`, covering selected queries whose `values_select` is empty.
- F5 states no remaining public-intent mismatch justifies a source edit.

## Residual Risk

F4/PO7: exact recovery of old or manually-created unmarked `values_list()` query pickles is underdetermined. The fallback prevents model-object crashes but cannot infer flat/named/tuple mode without V1 metadata.

Recommended handling: document in tests or release notes if needed, but do not change code for impossible exact recovery without a public compatibility requirement.

## Suggested Tests

Do not modify test files in this benchmark task. For a normal development branch, add tests for:

- restored `values().annotate()` returns dicts;
- restored `values_list()` returns tuples;
- restored `values_list(flat=True)` returns scalar values;
- restored `values_list(named=True)` returns namedtuples;
- restored annotation-only and extra-only selected queries do not use `ModelIterable`.

## Machine Check

In a K-capable environment, run:

```sh
cd fvk
kompile mini-django-query.k --backend haskell
kast --backend haskell django-queryset-query-spec.k
kprove django-queryset-query-spec.k
```

Keep all tests until the proof is machine-checked and the Django integration tests pass.

