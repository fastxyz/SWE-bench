# FINDINGS

Status: constructed, not machine-checked.

## F-001: Pre-V1 insert results skipped converters

- Evidence: E-001, E-002, E-003, E-004.
- Input: a model whose primary key is a `BigAutoField` subclass defining
  `from_db_value()` to return a wrapper object.
- Observed pre-V1 behavior: `create()` and supported `bulk_create()` paths
  assigned the raw returned integer to the model instance.
- Expected behavior: the returned value is passed through backend converters and
  field converters, including `from_db_value()`, before assignment.
- Status: resolved by current V1 code. `SQLInsertCompiler.execute_sql()` now
  routes fetched insert rows through `get_converters()` and
  `apply_converters()`.
- Related obligations: PO-001, PO-003, PO-004.

## F-002: Raw fields are not sufficient converter expressions

- Evidence: E-005, E-006.
- Input: a backend converter that inspects `expression.output_field` or
  `expression.field`, such as MySQL, SQLite, or Oracle operations.
- Observed risk: passing raw `Field` instances to `get_converters()` would not
  provide the same expression shape used by normal query conversion.
- Expected behavior: returned fields are wrapped as `Col` expressions via
  `field.get_col(query_meta.db_table)`.
- Status: resolved by current V1 code.
- Related obligations: PO-002.

## F-003: Fallback branch returns only the primary key

- Evidence: E-007.
- Input: an insert path with `returning_fields` truthy but without backend
  `RETURNING` support.
- Observed compatibility constraint: Django's existing fallback returns a single
  `last_insert_id()` value, which is the generated primary key, not all
  `returning_fields`.
- Expected behavior for this issue's domain: convert the single returned primary
  key using the primary-key field converters and preserve the existing one-column
  fallback shape.
- Status: resolved by current V1 code. The fallback uses `fields = [pk]` for
  conversion.
- Related obligations: PO-005.

## F-004: Returned rows must stay materialized

- Evidence: E-008.
- Input: `bulk_create()` on a backend that can return inserted rows.
- Observed risk: `apply_converters()` is a generator; returning it directly
  would break callers that inspect `len(returned_columns)`.
- Expected behavior: compiler output remains a list.
- Status: resolved by current V1 code. It returns `list(rows)` and converts rows
  back to tuples when converters are applied.
- Related obligations: PO-006.

## F-005: No additional V1 code bug found by the FVK audit

- Evidence: PO-001 through PO-007.
- Input: all three result-producing insert branches in the scoped model.
- Observed current behavior by static reasoning: every row returned by a backend
  helper is assigned to `rows`; a corresponding field list is assigned to
  `fields`; converters are computed from `field.get_col(table)`; converters are
  applied before the rows are returned to model assignment code.
- Expected behavior: same as the formal postconditions in `SPEC.md`.
- Status: V1 stands. No further source edit is justified by the audited public
  intent.
- Residual risk: the proof is constructed but not machine-checked; test removal
  is not recommended.

