# Public Evidence Ledger

Status: constructed for FVK audit, not machine-checked.

## E1: Reported issue

- Source: `benchmark/PROBLEM.md`
- Evidence: "durations-only expressions doesn't work on SQLite and MySQL"
- Obligation: duration-only expressions on non-native-duration backends must
  compile to values accepted by `DurationField` conversion.
- Status: encoded in `SPEC.md`, `duration-expression-spec.k`, PO1, PO2.

## E2: Concrete reproducer

- Source: `benchmark/PROBLEM.md`
- Evidence: `Experiment.objects.annotate(duration=F('estimated_time') + ...timedelta(1))`
- Obligation: `DurationField + timedelta` is an in-domain duration-only
  expression and must return a duration, not an interval string/date-time value.
- Status: encoded in claim `DURATION-FIELD-PLUS-LITERAL`; fixed by V1 and V2.

## E3: Storage contract

- Source: `repo/django/db/models/fields/__init__.py`
- Evidence: `DurationField.get_db_prep_value()` returns
  `duration_microseconds(value)` when `has_native_duration_field` is false.
- Obligation: non-native-duration duration results must remain integer
  microseconds until field conversion.
- Status: encoded in PO1 and PO2.

## E4: Current mixed arithmetic design

- Source: `repo/django/db/models/expressions.py`,
  `repo/django/db/backends/sqlite3/operations.py`,
  `repo/django/db/backends/mysql/operations.py`
- Evidence: `DurationExpression` uses
  `format_for_duration_arithmetic()` and `combine_duration_expression()` for
  date/time duration arithmetic.
- Obligation: mixed date/time plus duration behavior is a frame condition and
  must not be replaced with numeric addition.
- Status: encoded in PO4.

## E5: Temporal subtraction is a duration

- Source: `repo/django/db/models/expressions.py` and public tests in
  `repo/tests/expressions/tests.py`
- Evidence: `TemporalSubtraction.output_field = fields.DurationField()` and
  public tests compare `estimated_time` to `F('end') - F('start')`.
- Obligation: a temporal subtraction expression is duration-producing and is in
  scope when combined with another duration.
- Status: V1 gap recorded as F2; fixed in V2 and encoded in PO3.

## E6: Connector scope

- Source: problem wording plus existing SQLite backend guard
  `combine_duration_expression()` allowing only `+` and `-`.
- Evidence: the report uses addition; SQLite rejects other timedelta
  connectors as invalid.
- Obligation: this fix should not newly authorize invalid duration operators.
- Status: encoded in PO5.
