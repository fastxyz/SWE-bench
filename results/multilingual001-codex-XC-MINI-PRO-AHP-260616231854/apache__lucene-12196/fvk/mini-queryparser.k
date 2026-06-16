module MINI-QUERYPARSER-SYNTAX
  imports INT-SYNTAX
  imports STRING-SYNTAX

  syntax Query ::= "nullQuery"
                 | "other" "(" String ")"
                 | "phrase" "(" String "," Int ")"
                 | "multiPhrase" "(" String "," Int ")"
                 | "boost" "(" Query "," String ")"
  syntax QExp ::= Query
                | "applySlop" "(" Query "," Int ")"
  syntax KItem ::= "reboost" "(" String ")"
  syntax KResult ::= Query
endmodule

module MINI-QUERYPARSER
  imports MINI-QUERYPARSER-SYNTAX
  imports INT
  imports STRING

  configuration <k> $PGM:QExp </k>

  rule <k> applySlop(nullQuery, S:Int) => nullQuery </k>
  rule <k> applySlop(other(P:String), S:Int) => other(P) </k>
  rule <k> applySlop(phrase(P:String, OLD:Int), S:Int) => phrase(P, S) </k>
  rule <k> applySlop(multiPhrase(P:String, OLD:Int), S:Int) => multiPhrase(P, S) </k>
  rule <k> applySlop(boost(Q:Query, B:String), S:Int) => applySlop(Q, S) ~> reboost(B) </k>
  rule <k> Q:Query ~> reboost(B:String) => boost(Q, B) </k>
endmodule
