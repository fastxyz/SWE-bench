# FVK Findings

Status: constructed, not machine-checked.

## F1: Pre-fix duration-only arithmetic used interval/date-time formatting

- Classification: code bug, fixed by V1 and preserved by V2.
- Evidence: E1, E2, E3; PO1, PO2.
- Input: `F('estimated_time') + datetime.timedelta(days=1)` on SQLite/MySQL.
- Observed before the fix: SQLite routed two microsecond integers through
  `django_format_dtdelta()` and produced a formatted `timedelta` string; MySQL
  routed duration operands through `INTERVAL ... MICROSECOND`.
- Expected: a numeric microsecond result that the `DurationField` converter can
  turn into `datetime.timedelta`.
- Resolution: `DurationExpression.as_sql()` now detects duration-only `+` and
  `-`, compiles operands as stored values, and uses normal numeric
  `combine_expression()`.

## F2: V1 missed temporal subtraction as a duration-producing operand

- Classification: code bug in V1 completeness, fixed in V2.
- Evidence: E5; PO3.
- Input: `F('estimated_time') + (F('end') - F('start'))` on a non-native
  duration backend.
- Observed in V1 by static reasoning: the top-level expression entered
  `DurationExpression` because the left side was a `DurationField`, but the
  right side's raw `CombinedExpression.output_field` was not recognized as a
  duration even though `CombinedExpression.as_sql()` later compiles same-type
  temporal subtraction through `TemporalSubtraction`.
- Expected: temporal subtraction is a duration-producing operand, so the whole
  expression is duration-only and must use numeric microsecond arithmetic.
- Resolution: `has_duration_output()` now treats same-type
  `DateField`/`DateTimeField`/`TimeField` subtraction as duration output.

## F3: Mixed date/time plus duration behavior must remain on the interval path

- Classification: frame condition, satisfied by V2.
- Evidence: E4; PO4.
- Input: `F('start') + F('estimated_time')` or `F('start') +
  datetime.timedelta(days=1)`.
- Observed risk: a broad fix that always compiled durations as stored integers
  would break date/time arithmetic on MySQL and SQLite.
- Expected: mixed expressions continue to call backend duration formatting and
  `combine_duration_expression()`.
- Resolution: the numeric branch requires both operands to be duration output;
  otherwise the existing mixed path remains unchanged.

## F4: Invalid duration operators should not be newly accepted

- Classification: compatibility/frame condition, satisfied by V2.
- Evidence: E6; PO5.
- Input: `F('estimated_time') * datetime.timedelta(0)`.
- Expected: this fix does not expand the valid operator family beyond `+` and
  `-`.
- Resolution: the duration-only numeric branch is gated by
  `self.connector in (self.ADD, self.SUB)`.

## F5: No public API compatibility break found

- Classification: compatibility audit, no code change needed.
- Evidence: PO6.
- Input: public callers and subclasses of expression classes.
- Expected: no changed signatures, public return shapes, model storage format,
  or backend API contracts.
- Resolution: the edit only changes internal branch selection in
  `DurationExpression`; no public method signatures or backend hooks changed.

## Residual risk

The proof is constructed but not machine-checked. SQL parser acceptance and
database execution are reasoned from Django's existing backend hooks and are not
executed in this session. No tests were run.
