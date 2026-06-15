module MINI-DJANGO-DELETE-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax Int ::= "normalizeActive" "(" Int ")" [function]
  syntax Bool ::= "singleAlias" "(" Int "," Int ")" [function]
  syntax Shape ::= "direct" | "fallback"
                 | "deleteShape" "(" Int "," Int ")" [function]

  syntax KResult ::= Int | Bool | Shape
endmodule

module MINI-DJANGO-DELETE
  imports MINI-DJANGO-DELETE-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:Shape </k>

  rule normalizeActive(A:Int) => 1
    requires A ==Int 0
  rule normalizeActive(A:Int) => A
    requires A >Int 0

  rule singleAlias(A:Int, E:Int)
        => normalizeActive(A) ==Int 1 andBool E ==Int 0
    requires A >=Int 0 andBool E >=Int 0

  rule deleteShape(A:Int, E:Int) => direct
    requires singleAlias(A, E)
  rule deleteShape(A:Int, E:Int) => fallback
    requires notBool singleAlias(A, E)
endmodule
