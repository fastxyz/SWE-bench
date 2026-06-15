# Proof Obligations

Status: constructed, not machine-checked.

## PO1: Duration-only branch selection

- Claim: On non-native-duration backends, if the connector is `+` or `-` and
  both operands are duration-producing, `DurationExpression.as_sql()` selects
  numeric `combine_expression()` rather than backend
  `combine_duration_expression()`.
- Evidence: E1, E2, E3.
- Findings: F1.
- Status: discharged by V2 source inspection and K claims
  `DURATION-FIELD-PLUS-LITERAL`, `LITERAL-PLUS-DURATION-FIELD`, and
  `DURATION-FIELD-PLUS-DURATION-FIELD`.

## PO2: DurationValue stored-microsecond compilation

- Claim: In the duration-only branch, a `DurationValue` compiles through
  `Value.as_sql()` so its `DurationField.get_db_prep_value()` conversion yields
  integer microseconds instead of interval SQL.
- Evidence: E2, E3.
- Findings: F1.
- Status: discharged by V2 source inspection and K claim
  `DURATION-FIELD-PLUS-LITERAL`.

## PO3: Temporal subtraction counts as duration output

- Claim: Same-type temporal subtraction (`DateField - DateField`,
  `DateTimeField - DateTimeField`, `TimeField - TimeField`) is
  duration-producing for purposes of duration-only arithmetic.
- Evidence: E5.
- Findings: F2.
- Status: V1 failed this obligation; V2 discharges it with the added
  `CombinedExpression`/`SUB` temporal-type check in `has_duration_output()` and
  K claim `TEMPORAL-SUBTRACTION-PLUS-DURATION`.

## PO4: Mixed date/time arithmetic frame condition

- Claim: If one operand is date/time-producing and the other is
  duration-producing, the existing mixed date/time duration path remains in
  effect.
- Evidence: E4.
- Findings: F3.
- Status: discharged because V2 requires both operands to be duration output
  before taking the numeric branch; K claim `MIXED-DATETIME-PLUS-DURATION`
  models the preserved path.

## PO5: Invalid connector exclusion

- Claim: Operators outside `+` and `-` do not take the duration-only numeric
  branch.
- Evidence: E6.
- Findings: F4.
- Status: discharged by the connector guard and K claim
  `MULTIPLY-STAYS-ON-BACKEND-DURATION-PATH`.

## PO6: Public compatibility

- Claim: The fix changes no public API signatures, backend hook signatures,
  field storage formats, or tests.
- Evidence: source diff and public compatibility audit.
- Findings: F5.
- Status: discharged by static source review.
