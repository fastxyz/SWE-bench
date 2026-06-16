# Iteration Guidance

Status: constructed, not machine-checked.

## Code Guidance Applied

Apply the V2 source change justified by F1 and PO4:

- keep V1's exclusion of column-free order-by grouping expressions;
- keep V1's raw SQL exception;
- add preservation for expressions whose flattened sources expose non-empty
  external columns through `get_external_cols()`.

This has been applied to `repo/django/db/models/sql/compiler.py`.

## Tests To Add Later

Do not edit tests in this task. In a normal Django development environment, add
or confirm tests for:

- `annotate(...).order_by('?').values(...)` does not add random SQL to
  `GROUP BY`;
- ordering by a related field still contributes grouping and can split rows;
- raw SQL ordering remains grouped;
- ordering by a non-selected subquery annotation with multivalued external
  columns remains grouped.

## Machine Verification To Run Later

```sh
cd fvk
kompile mini-django-groupby.k --backend haskell
kast --backend haskell django-groupby-spec.k
kprove django-groupby-spec.k
```

Keep all tests until the proof has been machine-checked and the Django test
suite has been run in an execution-capable environment.
