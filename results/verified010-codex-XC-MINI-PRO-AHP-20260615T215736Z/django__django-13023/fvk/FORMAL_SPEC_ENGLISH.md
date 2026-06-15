# Formal Spec English

Status: constructed, not machine-checked.

The K claims in `decimal-field-spec.k` mean:

1. For any precision, `toPython(none, precision)` returns `returnNone`.
2. For any float-equivalent input and precision, `toPython(floatInput(f), precision)` returns `returnDecimal(decimalFromFloat(f, precision))`.
3. For any valid non-float decimal constructor input represented by `validInput(d)`, `toPython(validInput(d), precision)` returns `returnDecimal(decimal(d))`.
4. For invalid decimal syntax represented by `invalidSyntaxInput`, `toPython(invalidSyntaxInput, precision)` returns `validationError(invalidSyntaxInput)`.
5. For dictionary input represented by `dictInput`, where the decimal constructor raises `TypeError`, `toPython(dictInput, precision)` returns `validationError(dictInput)`.
6. For malformed tuple/value input represented by `malformedTupleInput`, where the decimal constructor raises `ValueError`, `toPython(malformedTupleInput, precision)` returns `validationError(malformedTupleInput)`.
7. For an abstract conversion branch represented by `otherExceptionInput`, outside the public conversion-failure set for this issue, `toPython(otherExceptionInput, precision)` returns `rawException(otherError)`. This is a frame condition showing the V1 fix is targeted rather than a catch-all.

There are no loop circularities. Partial correctness is enough for this unit because the audited method has no loop or recursion.
