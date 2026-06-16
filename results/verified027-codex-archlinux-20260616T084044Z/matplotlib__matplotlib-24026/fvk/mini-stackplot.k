module MINI-STACKPLOT-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports LIST-SYNTAX

  syntax Color ::= "C0" | "C1" | "C2" | "C3" | "C4"
                 | "R" | "G" | "B" | "K"
  syntax Axis ::= "axis" "(" Int "," List ")"
  syntax Result ::= "result" "(" List "," Axis "," Bool ")"
  syntax Stmt ::= "stackplotExplicit" "(" List "," Int "," Axis ")"
                | "stackplotDefault" "(" Int "," Axis ")"

  syntax List ::= takeCycle(List, Int) [function]
  syntax List ::= advance(List, Int) [function]
  syntax Axis ::= advanceAxis(Axis, Int) [function]
  syntax Bool ::= isCycleReference(Color) [function]
endmodule

module MINI-STACKPLOT
  imports MINI-STACKPLOT-SYNTAX
  imports INT
  imports BOOL
  imports LIST

  configuration <k> $PGM:Stmt </k>

  rule <k> stackplotExplicit(CS, M, AX) =>
           result(takeCycle(CS, M), AX, false) </k>
    requires M >=Int 0

  rule <k> stackplotDefault(M, axis(I, CS)) =>
           result(takeCycle(advance(CS, I), M),
                  axis(I +Int M, CS),
                  true) </k>
    requires M >=Int 0 andBool I >=Int 0

  rule takeCycle(CS, 0) => .List
  rule takeCycle(ListItem(C) CS, N) =>
       ListItem(C) takeCycle(advance(ListItem(C) CS, 1), N -Int 1)
    requires N >Int 0

  rule advance(CS, 0) => CS
  rule advance(ListItem(C) CS, N) => advance(CS ListItem(C), N -Int 1)
    requires N >Int 0

  rule advanceAxis(axis(I, CS), N) => axis(I +Int N, CS)

  rule isCycleReference(C0) => true
  rule isCycleReference(C1) => true
  rule isCycleReference(C2) => true
  rule isCycleReference(C3) => true
  rule isCycleReference(C4) => true
  rule isCycleReference(R) => false
  rule isCycleReference(G) => false
  rule isCycleReference(B) => false
  rule isCycleReference(K) => false
endmodule
