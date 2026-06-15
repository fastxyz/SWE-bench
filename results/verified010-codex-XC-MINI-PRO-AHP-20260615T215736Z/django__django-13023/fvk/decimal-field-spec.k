// Constructed, not machine-checked.
requires "mini-decimal-field.k"

module DECIMAL-FIELD-SPEC
  imports MINI-DECIMAL-FIELD

  // SPEC-PROVENANCE:
  // - from_code: DecimalField.to_python() returns None unchanged.
  // - from_base_contract: Field.to_python() returns the converted value and
  //   raises ValidationError only when data cannot be converted.
  claim
    <k> toPython(none, PREC:Int) => returnNone </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_test: tests/model_fields/test_decimalfield.py checks that
  //   floats are converted through the field context and honor max_digits.
  // - from_code: DecimalField.to_python() has a separate float branch before
  //   decimal.Decimal(value).
  claim
    <k> toPython(floatInput(F:Int), PREC:Int) => returnDecimal(decimalFromFloat(F, PREC)) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_test: tests/model_fields/test_decimalfield.py checks integer
  //   and string decimal inputs convert to Decimal values.
  // - from_base_contract: successful conversion returns the converted value.
  claim
    <k> toPython(validInput(D:Int), PREC:Int) => returnDecimal(decimal(D)) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_test: tests/model_fields/test_decimalfield.py checks 'abc'
  //   raises ValidationError with the invalid decimal message.
  // - from_code: decimal.Decimal(value) signals invalid syntax as
  //   decimal.InvalidOperation, which V1 catches.
  claim
    <k> toPython(invalidSyntaxInput, PREC:Int) => validationError(invalidSyntaxInput) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "A call to DecimalField.to_python() with a dictionary as
  //   the value parameter produces TypeError instead of ValidationError."
  // - from_base_contract: conversion failures raise ValidationError.
  // - conflicts: pre-V1 leaked raw TypeError; V1 catches TypeError.
  claim
    <k> toPython(dictInput, PREC:Int) => validationError(dictInput) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_base_contract: data that cannot be converted raises ValidationError.
  // - from_adjacent_numeric_fields: IntegerField and FloatField to_python()
  //   normalize TypeError and ValueError conversion failures as invalid input.
  // - from_code: V1 catches ValueError in the same decimal.Decimal(value)
  //   conversion guard as TypeError and InvalidOperation.
  claim
    <k> toPython(malformedTupleInput, PREC:Int) => validationError(malformedTupleInput) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: V1 changes only the decimal.Decimal(value) conversion guard.
  // - from_frame_condition: exceptions outside the known conversion-failure
  //   set are not silently converted by this targeted fix.
  claim
    <k> toPython(otherExceptionInput, PREC:Int) => rawException(otherError) </k>
    [all-path]
endmodule
