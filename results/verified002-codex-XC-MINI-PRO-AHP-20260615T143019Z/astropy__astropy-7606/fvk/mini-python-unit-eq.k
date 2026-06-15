module MINI-PYTHON-UNIT-EQ-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX

  syntax UnitVal ::= "unrec" "(" String ")" | "recognized"
  syntax Conv ::= "ok" "(" UnitVal ")" | "raises" "(" Exc ")"
  syntax Exc ::= "valueError" | "unitsError" | "typeError"

  syntax KItem ::= eqUnrecognized(String, Conv)
                 | neUnrecognized(String, Conv)

  syntax KResult ::= Bool
endmodule

module MINI-PYTHON-UNIT-EQ
  imports MINI-PYTHON-UNIT-EQ-SYNTAX
  imports BOOL
  imports STRING

  configuration <k> $PGM:K </k>

  // Mini semantics for UnrecognizedUnit.__eq__ after Unit(other,
  // parse_strict='silent') has been abstracted to a conversion outcome.
  rule <k> eqUnrecognized(S:String, ok(unrec(T:String)))
        => S ==String T ... </k>
  rule <k> eqUnrecognized(_S:String, ok(recognized))
        => false ... </k>
  rule <k> eqUnrecognized(_S:String, raises(valueError))
        => false ... </k>
  rule <k> eqUnrecognized(_S:String, raises(unitsError))
        => false ... </k>
  rule <k> eqUnrecognized(_S:String, raises(typeError))
        => false ... </k>

  rule <k> neUnrecognized(S:String, ok(unrec(T:String)))
        => notBool (S ==String T) ... </k>
  rule <k> neUnrecognized(_S:String, ok(recognized))
        => true ... </k>
  rule <k> neUnrecognized(_S:String, raises(valueError))
        => true ... </k>
  rule <k> neUnrecognized(_S:String, raises(unitsError))
        => true ... </k>
  rule <k> neUnrecognized(_S:String, raises(typeError))
        => true ... </k>
endmodule
