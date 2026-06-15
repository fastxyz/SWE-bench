# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
tests, Python, or database code were executed.

## What is proved

For non-native-duration backends, `DurationExpression.as_sql()` is partially
correct for the audited branch:

- duration-only `+` and `-` expressions compile to numeric combinations of
  stored microsecond operands;
- `DurationValue` literals in that branch compile as integer microseconds;
- temporal subtraction operands are recognized as duration-producing;
- mixed date/time plus duration expressions remain on the backend interval path;
- invalid connectors do not enter the duration-only numeric branch.

## Claims

The K claims are in `fvk/duration-expression-spec.k`:

- `DURATION-FIELD-PLUS-LITERAL`
- `LITERAL-PLUS-DURATION-FIELD`
- `DURATION-FIELD-PLUS-DURATION-FIELD`
- `TEMPORAL-SUBTRACTION-PLUS-DURATION`
- `MIXED-DATETIME-PLUS-DURATION`
- `MULTIPLY-STAYS-ON-BACKEND-DURATION-PATH`

## Proof sketch

1. `CombinedExpression.as_sql()` routes non-native expressions with at least
   one duration operand into `DurationExpression`. This is the only production
   code path changed by the fix.

2. `DurationExpression.as_sql()` computes `duration_only` from three facts:
   the connector is `+` or `-`, the left side has duration output, and the right
   side has duration output.

3. `has_duration_output()` is true for explicit `DurationField` output and,
   after V2, for same-type temporal subtraction expressions. This discharges
   PO1 and PO3.

4. In the duration-only branch, `compile(..., duration_only=True)` avoids
   `format_for_duration_arithmetic()`. For direct `DurationValue` literals it
   calls `Value.as_sql()`, which uses the `DurationField` preparation path and
   produces stored microseconds. This discharges PO2.

5. The duration-only branch calls `connection.ops.combine_expression()`, so
   SQLite and MySQL receive ordinary numeric `+` or `-` over microsecond values.
   This removes the pre-fix path that produced formatted timedelta strings or
   interval SQL for duration-only outputs. This discharges F1.

6. If either side is not duration output, `duration_only` is false. The code
   keeps the previous `combine_duration_expression()` path and preserves mixed
   date/time arithmetic behavior. This discharges PO4.

7. If the connector is not `+` or `-`, `duration_only` is false even when both
   operands are durations. This preserves the previous invalid-operator behavior
   and discharges PO5.

8. No public signatures, backend hook signatures, storage representations, or
   tests changed. This discharges PO6.

## Machine-check commands not run

The FVK method requires exact commands, but the task forbids running K tooling.
These are the commands a human could run later:

```sh
kompile fvk/mini-duration-expressions.k --backend haskell
kast --backend haskell fvk/duration-expression-spec.k
kprove fvk/duration-expression-spec.k
```

Expected result after a real machine check: `kprove` reduces all listed claims
to `#Top`.

## Test guidance

No tests were modified or run. Because the proof is not machine-checked, no
test removal is recommended. Future tests should cover the reported case,
reversed operands, `DurationField + DurationField`, temporal subtraction plus a
duration, and a mixed date/time plus duration frame case.
