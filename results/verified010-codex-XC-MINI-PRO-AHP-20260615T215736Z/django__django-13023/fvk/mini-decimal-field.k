// Constructed, not machine-checked.
// Minimal K semantics fragment for DecimalField.to_python().
// This abstracts Python's decimal module into input classes that distinguish
// the observable branch relevant to django__django-13023: raw TypeError vs.
// Django ValidationError.

module MINI-DECIMAL-FIELD-SYNTAX
  imports INT-SYNTAX

  syntax Input ::= none
                 | floatInput(Int)
                 | validInput(Int)
                 | invalidSyntaxInput
                 | dictInput
                 | malformedTupleInput
                 | otherExceptionInput

  syntax DecimalValue ::= decimal(Int)
                        | decimalFromFloat(Int, Int)

  syntax Exc ::= invalidOperation | typeError | valueError | otherError

  syntax Conv ::= ok(DecimalValue)
                | raises(Exc)
                | decimalDecimal(Input) [function]

  syntax Outcome ::= returnNone
                   | returnDecimal(DecimalValue)
                   | validationError(Input)
                   | rawException(Exc)

  syntax Pgm ::= toPython(Input, Int)
               | handle(Conv, Input)

  syntax KResult ::= Outcome | Conv
endmodule

module MINI-DECIMAL-FIELD
  imports MINI-DECIMAL-FIELD-SYNTAX
  imports INT

  configuration <k> $PGM:Pgm </k>

  // Model of decimal.Decimal(value) on the equivalence classes used by the
  // public issue and the surrounding Django field contract.
  rule decimalDecimal(validInput(D)) => ok(decimal(D))
  rule decimalDecimal(invalidSyntaxInput) => raises(invalidOperation)
  rule decimalDecimal(dictInput) => raises(typeError)
  rule decimalDecimal(malformedTupleInput) => raises(valueError)
  rule decimalDecimal(otherExceptionInput) => raises(otherError)

  // DecimalField.to_python().
  rule <k> toPython(none, _PREC:Int) => returnNone </k>
  rule <k> toPython(floatInput(F), PREC) => returnDecimal(decimalFromFloat(F, PREC)) </k>
  rule <k> toPython(validInput(D), _PREC:Int) => handle(decimalDecimal(validInput(D)), validInput(D)) </k>
  rule <k> toPython(invalidSyntaxInput, _PREC:Int) => handle(decimalDecimal(invalidSyntaxInput), invalidSyntaxInput) </k>
  rule <k> toPython(dictInput, _PREC:Int) => handle(decimalDecimal(dictInput), dictInput) </k>
  rule <k> toPython(malformedTupleInput, _PREC:Int) => handle(decimalDecimal(malformedTupleInput), malformedTupleInput) </k>
  rule <k> toPython(otherExceptionInput, _PREC:Int) => handle(decimalDecimal(otherExceptionInput), otherExceptionInput) </k>

  // The try/except block in V1 catches exactly the conversion failures that
  // public intent treats as invalid decimal input.
  rule <k> handle(ok(D), _V:Input) => returnDecimal(D) </k>
  rule <k> handle(raises(invalidOperation), V) => validationError(V) </k>
  rule <k> handle(raises(typeError), V) => validationError(V) </k>
  rule <k> handle(raises(valueError), V) => validationError(V) </k>
  rule <k> handle(raises(otherError), _V:Input) => rawException(otherError) </k>
endmodule
