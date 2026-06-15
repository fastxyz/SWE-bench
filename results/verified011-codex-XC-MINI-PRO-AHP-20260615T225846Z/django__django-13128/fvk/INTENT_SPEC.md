# Intent Spec

Status: constructed from public evidence, not machine-checked.

## Required Behavior

I1. Temporal subtraction without `ExpressionWrapper`

Source: `benchmark/PROBLEM.md`.

Evidence: "make temporal subtraction work without ExpressionWrapper" and the
reported annotation:

```python
delta=F('end') - F('start') + Value(datetime.timedelta(), output_field=DurationField())
```

Obligation: for two operands whose output fields are the same temporal field
type (`DateField`, `DateTimeField`, or `TimeField`), subtraction is a duration
expression. Its inferred `output_field` must be `DurationField` before a parent
expression performs mixed-type inference.

I2. Reported nested expression must not raise the mixed-type error

Source: `benchmark/PROBLEM.md`.

Evidence: the reported failure is:

```text
Expression contains mixed types: DateTimeField, DurationField. You must set output_field.
```

Obligation: in the issue expression, `F('end') - F('start')` must contribute a
`DurationField` to the outer addition, so the outer expression sees
`DurationField + DurationField`.

I3. Existing temporal SQL behavior is preserved

Source: local code and public tests under `repo/tests/expressions/tests.py`.

Evidence: `CombinedExpression.as_sql()` already routes same-type temporal
subtraction through `TemporalSubtraction`, and existing public tests use
`ExpressionWrapper(..., output_field=DurationField())` around date, datetime,
and time subtraction.

Obligation: the fix must align output-field inference with that existing SQL
specialization. It must not replace or bypass backend-specific
`TemporalSubtraction.as_sql()` behavior.

I4. Non-temporal and mismatched arithmetic remains governed by existing generic
inference

Source: `BaseExpression._resolve_output_field()` and the issue scope.

Obligation: outside same-type temporal subtraction, `CombinedExpression` should
delegate to the existing generic output-field inference so unrelated arithmetic
semantics and errors are preserved.

## Domain

The verified domain is resolved `CombinedExpression` operands whose
`output_field.get_internal_type()` result is known. Unresolved `F()` objects
before query resolution are outside this unit; Django resolves them before SQL
compilation and annotation result conversion.

## Default Assumptions

- `DateField`, `DateTimeField`, and `TimeField` are the temporal field family
  relevant to `TemporalSubtraction`, matching the existing SQL predicate.
- `DurationField` is the output type for temporal subtraction, matching
  `TemporalSubtraction.output_field`.
- The task does not require a broader redesign of all duration arithmetic
  inference, such as `DateTimeField + DurationField` annotations without an
  explicit output field, because the public issue is specifically temporal
  subtraction.
