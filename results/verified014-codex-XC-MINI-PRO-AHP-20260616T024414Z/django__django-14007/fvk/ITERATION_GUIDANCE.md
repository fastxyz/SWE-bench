# ITERATION GUIDANCE

Status: constructed, not machine-checked.

## Decision

V1 stands unchanged after FVK audit.

The audit found the original root cause and confirmed that the current compiler
change discharges it for the scoped behavior: insert-returned rows are fetched,
associated with the fields that correspond to the returned columns, sent through
the normal converter pipeline, materialized, and only then returned to model
assignment code.

## Why No Further Code Edit Is Justified

- F-001 / PO-001: the central bug is fixed at the compiler source of returned
  rows, so both `create()` and `bulk_create()` share the fix.
- F-002 / PO-002: using `field.get_col(table)` is necessary and already present.
- F-003 / PO-005: the fallback branch converts only the primary key because only
  the primary key is fetched by `last_insert_id()`.
- F-004 / PO-006: materialization and tuple row shape are preserved.
- F-005 / PO-008: no public signature or caller protocol changed.

## Next Tests To Add Or Keep

Do not modify tests in this benchmark. In a normal development branch, add or
keep tests for:

1. `create()` with a custom `BigAutoField.from_db_value()` returning a wrapper.
2. `bulk_create()` with the same custom field on a row-returning backend.
3. A returning field that exercises backend converters plus `from_db_value()`.
4. The fallback `last_insert_id()` path for an auto primary key with converters.

## Machine-Checking Follow-Up

The proof is constructed only. Before making any test-removal or verification
claim stronger than this audit, complete and run:

```sh
kompile fvk/mini-django-insert.k --backend haskell
kast --backend haskell fvk/django-insert-returning-spec.k
kprove fvk/django-insert-returning-spec.k
```

Expected result after turning the sketch into executable K: `#Top`.

