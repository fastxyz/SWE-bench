// Constructed mini semantics for the precision-relevant floatformat slice.
// This is not full Python or full Django. It preserves the observable axis
// under audit: whether Decimal input reaches rendering as the exact Decimal or
// as a Decimal reconstructed from binary float.

module MINI-FLOATFORMAT-SYNTAX
  imports INT-SYNTAX
  imports STRING-SYNTAX

  syntax Dec ::= dec(Int, Int, Int)
  // dec(Sign, Coefficient, Scale) represents
  // (-1)^Sign * Coefficient * 10 ^ (-Scale).

  syntax Value ::= decimal(Dec)
                 | nondecimal(String)
                 | invalidValue

  syntax Arg ::= places(Int)
               | invalidArg(String)

  syntax Out ::= rendered(String)
               | empty

  syntax Out ::= render(Dec, Int) [function]
               | original(Value) [function]

  syntax Dec ::= decimalFromRepr(String) [function]

  syntax KItem ::= floatformat(Value, Arg)
  syntax KResult ::= Out
endmodule

module MINI-FLOATFORMAT
  imports MINI-FLOATFORMAT-SYNTAX

  configuration <k> $PGM:K </k>

  // V1 behavior: an existing Decimal is passed to rendering unchanged.
  rule <k> floatformat(decimal(D:Dec), places(P:Int)) => render(D, P) ... </k>

  // Frame condition: non-Decimal inputs keep the existing repr/fallback path.
  rule <k> floatformat(nondecimal(R:String), places(P:Int)) => render(decimalFromRepr(R), P) ... </k>

  // Invalid numeric conversion remains outside the numeric formatting domain.
  rule <k> floatformat(invalidValue, places(_P:Int)) => empty ... </k>

  // Invalid arguments return the input display string.
  rule <k> floatformat(V:Value, invalidArg(_A:String)) => original(V) ... </k>

  rule original(decimal(dec(0, C:Int, S:Int))) => rendered("decimal-string")
  rule original(nondecimal(R:String)) => rendered(R)
  rule original(invalidValue) => empty

  // Concrete issue point. A full semantics would define decimal rendering
  // generally; this artifact pins the public issue value as an externally
  // derived Decimal arithmetic fact.
  rule render(dec(0, 4212345678901234567890, 20), 20)
    => rendered("42.12345678901234567890")
endmodule
