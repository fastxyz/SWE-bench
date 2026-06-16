module MINI-FLOATFORMAT-SYNTAX
  imports INT-SYNTAX
  imports STRING-SYNTAX

  syntax Pgm ::= rawPrec(Int, Int)
               | safePrec(Int, Int)
               | floatformatZero(Int, Int)
               | floatformatZeroNegative(Int)

  syntax KResult ::= Int | String
endmodule

module MINI-FLOATFORMAT
  imports MINI-FLOATFORMAT-SYNTAX
  imports INT
  imports BOOL
  imports STRING

  configuration <k> $PGM:Pgm </k>

  // Decimal zero has coefficient digit length 1 and exponent -S.
  // For nonnegative precision P, Django's raw pre-fix precision is:
  // abs(P) + (1 + exponent) + 1 = P + 2 - S.
  syntax Int ::= rawPrecision(Int, Int) [function]
  rule rawPrecision(P:Int, S:Int) => P +Int 2 -Int S

  syntax Int ::= maxOne(Int) [function]
  rule maxOne(N:Int) => N requires N >=Int 1
  rule maxOne(N:Int) => 1 requires N <Int 1

  rule <k> rawPrec(P:Int, S:Int) => rawPrecision(P, S) </k>
  rule <k> safePrec(P:Int, S:Int) => maxOne(rawPrecision(P, S)) </k>

  syntax String ::= zeroFixed(Int) [function]
  rule zeroFixed(0) => "0"
  rule zeroFixed(P:Int) => "0." +String zeroDigits(P) requires P >Int 0

  syntax String ::= zeroDigits(Int) [function]
  rule zeroDigits(0) => ""
  rule zeroDigits(N:Int) => "0" +String zeroDigits(N -Int 1) requires N >Int 0

  rule <k> floatformatZero(P:Int, S:Int) => zeroFixed(P) </k>
    requires P >=Int 0
     andBool S >=Int 0
     andBool maxOne(rawPrecision(P, S)) >=Int 1

  rule <k> floatformatZeroNegative(P:Int) => "0" </k>
    requires P <Int 0
endmodule
