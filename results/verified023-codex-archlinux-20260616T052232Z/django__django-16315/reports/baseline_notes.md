# Baseline Notes

## Root Cause

`QuerySet.bulk_create()` validates `update_fields` and `unique_fields` by resolving
the provided model field names to `Field` objects, but it did not keep those
resolved fields. The original strings were passed into `InsertQuery` and then into
backend `on_conflict_suffix_sql()` methods. Those backend methods quote their
inputs as database identifiers, so models using `db_column` generated conflict
SQL with attribute names such as `"blacklistid"` instead of database column names
such as `"BlacklistID"`.

## Changed Files

- `repo/django/db/models/query.py`: After preparing the objects for
  `bulk_create()`, the already-validated `update_fields` and `unique_fields`
  names are resolved to model `Field` objects before they are passed to
  `_batched_insert()` and stored on `InsertQuery`.
- `repo/django/db/models/sql/compiler.py`: The insert compiler now passes
  `Field.column` values to `connection.ops.on_conflict_suffix_sql()` so backend
  conflict clauses use real database column names.

## Assumptions

- `update_fields` and `unique_fields` are public API inputs expressed as model
  field names, with the existing `"pk"` alias in `unique_fields` preserved by the
  earlier normalization in `bulk_create()`.
- Backend `on_conflict_suffix_sql()` implementations should continue receiving
  plain identifier strings; the compiler is the appropriate boundary for turning
  model `Field` objects into database column names.
- The source fix must be covered by hidden tests, since this task forbids
  modifying tests or running the test suite.

## Alternatives Considered

- Changing the backend `on_conflict_suffix_sql()` implementations to understand
  `Field` objects was rejected because those methods are lower-level SQL helpers
  that currently operate on identifier strings and quote them directly.
- Returning resolved fields from `_check_bulk_create_options()` was rejected as a
  larger API change to an internal validation helper when the same resolution can
  be performed locally in `bulk_create()` after validation.
- Treating the supplied names as `db_column` values was rejected because Django's
  `bulk_create()` API accepts model field names, not database column names.
