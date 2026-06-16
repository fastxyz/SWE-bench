module MINI-UP028-FIX-SYNTAX
  imports STRING-SYNTAX

  syntax IterKind ::= "bareTuple" | "preserved"
  syntax FixInput ::= "iter" "(" IterKind "," String ")"
  syntax FixExp ::= "fix" "(" FixInput ")"
  syntax KResult ::= String
endmodule

module MINI-UP028-FIX
  imports MINI-UP028-FIX-SYNTAX
  imports STRING

  configuration <k> $PGM:FixExp </k>

  rule <k> fix(iter(bareTuple, S:String)) => ("yield from (" +String S) +String ")" </k>
  rule <k> fix(iter(preserved, S:String)) => "yield from " +String S </k>
endmodule
