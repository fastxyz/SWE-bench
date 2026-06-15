module MINI-NUMBERFORMAT-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax Sign ::= "pos" | "neg"
  syntax Out ::= FixedZero(Sign, Int)
               | Scientific
               | Other
  syntax Call ::= "formatDecimal" "(" Sign "," Bool "," Int "," Int "," Int "," Bool ")"
  syntax KResult ::= Out
endmodule

module MINI-NUMBERFORMAT
  imports MINI-NUMBERFORMAT-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:Call </k>

  // formatDecimal(Sign, IsZero, Exponent, DigitLength, DecimalPos, Cutoff)
  //
  // Cutoff abstracts abs(exponent) + len(digits) > 200 from the Django code.
  // FixedZero(Sign, N) abstracts the downstream string shape:
  //   optional sign + "0" + decimal separator + N zero fractional digits.

  rule <k> formatDecimal(SIGN:Sign, true, EXP:Int, LEN:Int, N:Int, CUTOFF:Bool)
        => FixedZero(SIGN, N) </k>
    requires N >=Int 0

  rule <k> formatDecimal(SIGN:Sign, false, EXP:Int, LEN:Int, N:Int, CUTOFF:Bool)
        => FixedZero(SIGN, N) </k>
    requires N >=Int 0
     andBool EXP <Int 0
     andBool EXP +Int LEN <=Int 0 -Int N

  rule <k> formatDecimal(SIGN:Sign, false, EXP:Int, LEN:Int, N:Int, true)
        => Scientific </k>
    requires N >=Int 0
     andBool notBool (EXP <Int 0 andBool EXP +Int LEN <=Int 0 -Int N)

  rule <k> formatDecimal(SIGN:Sign, false, EXP:Int, LEN:Int, N:Int, false)
        => Other </k>
    requires N >=Int 0
     andBool notBool (EXP <Int 0 andBool EXP +Int LEN <=Int 0 -Int N)
endmodule
