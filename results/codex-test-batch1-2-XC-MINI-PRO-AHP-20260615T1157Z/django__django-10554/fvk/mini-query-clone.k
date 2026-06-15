module MINI-QUERY-CLONE-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports MAP-SYNTAX

  syntax QId ::= "orig" | "derived" | "c1" | "c2" | "d1" | "d2"
  syntax Kids ::= "noKids" | "kids" "(" QId "," QId ")"
  syntax Query ::= "query" "(" Int "," Int "," Kids ")"
  syntax Status ::= "ok" | "error"

  syntax Cmd ::= "deriveValuesPk" "(" QId "," QId "," QId "," QId ")"
               | "assertOrderable" "(" QId ")"
               | Cmd ";" Cmd [left]

  syntax KResult ::= Status
endmodule

module MINI-QUERY-CLONE
  imports MINI-QUERY-CLONE-SYNTAX
  imports INT
  imports BOOL
  imports MAP

  configuration
    <k> $PGM:Cmd </k>
    <queries> .Map </queries>
    <status> ok </status>

  rule <k> C1:Cmd ; C2:Cmd => C1 ~> C2 ... </k>

  // Model of V1: deriving values_list('pk') from a combined query clones the
  // combined child queries before narrowing the derived select lists.
  rule
    <k> deriveValuesPk(Q, D, D1, D2) => .K ... </k>
    <queries>
      M:Map
      Q  |-> query(W, O, kids(C1, C2))
      C1 |-> query(W1, O1, noKids)
      C2 |-> query(W2, O2, noKids)
      =>
      M
      Q  |-> query(W, O, kids(C1, C2))
      C1 |-> query(W1, O1, noKids)
      C2 |-> query(W2, O2, noKids)
      D  |-> query(1, 0, kids(D1, D2))
      D1 |-> query(1, O1, noKids)
      D2 |-> query(1, O2, noKids)
    </queries>

  rule
    <k> assertOrderable(Q) => .K ... </k>
    <queries>
      ...
      Q  |-> query(_, O, kids(C1, C2))
      C1 |-> query(W1, _, noKids)
      C2 |-> query(W2, _, noKids)
      ...
    </queries>
    <status> ok </status>
    requires O <=Int W1 andBool O <=Int W2

  rule
    <k> assertOrderable(Q) => .K ... </k>
    <queries>
      ...
      Q  |-> query(_, O, kids(C1, C2))
      C1 |-> query(W1, _, noKids)
      C2 |-> query(W2, _, noKids)
      ...
    </queries>
    <status> ok => error </status>
    requires notBool (O <=Int W1 andBool O <=Int W2)
endmodule
