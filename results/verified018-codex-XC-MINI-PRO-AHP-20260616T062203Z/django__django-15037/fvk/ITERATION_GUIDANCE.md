# Iteration Guidance

Status: V1 confirmed unchanged.

## Decision

Do not edit production code in this FVK pass. The findings that would have
blocked V1 are resolved by the existing V1 patch:

- F1 maps to O1 and is resolved by emitting `to_field` for non-primary-key
  targets.
- F2 maps to O3 and is resolved by using `normalize_table_columns()` instead of
  the raw target database column.
- F3 maps to O2 and is resolved by comparing against the target table's actual
  primary-key column, not against the literal string `id`.
- F4 maps to O4/O5 and shows the compatibility frame is preserved.

## Recommended Next Tests

Do not modify tests in this benchmark. In a normal Django contribution, add
focused `inspectdb` coverage for:

- a foreign key referencing a unique non-primary-key target field;
- a foreign key referencing a target primary key whose DB column is not `id`;
- a non-primary-key target column whose generated Django field name differs from
  its database column;
- a unique or primary-key local relation that still generates `OneToOneField`
  with the same pre-existing behavior plus `to_field` only when needed.

## Residual Risk

- The proof is constructed, not machine-checked.
- Tests, Python, and K tooling were intentionally not run.
- Composite foreign keys remain outside the audited contract because the
  existing `get_relations()` API exposes a single target column per local
  relation entry.

## Commands To Run Outside This Environment

For the abstract K artifacts committed under `fvk/`, the expected machine-check
sequence is:

```sh
kompile fvk/mini-inspectdb.k --backend haskell
kast --backend haskell fvk/inspectdb-spec.k
kprove fvk/inspectdb-spec.k
```

If Django tests are available outside this benchmark, run the targeted
`inspectdb` tests for the cases above and the existing inspectdb test module.
