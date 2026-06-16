module MINI-SQF-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports ID-SYNTAX

  syntax Factor ::= Id
                  | Factor "*" Factor [left]
  syntax Pair ::= "(" Factor "," Int ")"
  syntax Pairs ::= ".Pairs"
                 | Pair ";" Pairs [right]

  syntax Pairs ::= combine(Pairs) [function]
                 | insert(Factor, Int, Pairs) [function]
  syntax Bool ::= shouldCombine(Int, Bool) [function]
endmodule

module MINI-SQF
  imports MINI-SQF-SYNTAX
  imports INT
  imports BOOL

  // Abstract model of _combine_factors.
  rule combine(.Pairs) => .Pairs
  rule combine((F:Factor, K:Int) ; REST:Pairs)
    => insert(F, K, combine(REST))

  rule insert(F:Factor, K:Int, .Pairs)
    => (F, K) ; .Pairs

  rule insert(F:Factor, K:Int, (G:Factor, K:Int) ; REST:Pairs)
    => (G * F, K) ; REST

  rule insert(F:Factor, K:Int, (G:Factor, L:Int) ; REST:Pairs)
    => (G, L) ; insert(F, K, REST)
    requires K =/=Int L

  // Abstract model of the V1 gate: exactly one generator and no ambiguity.
  rule shouldCombine(1, true) => true
  rule shouldCombine(1, false) => false
  rule shouldCombine(N:Int, SAFE:Bool) => false
    requires N =/=Int 1
endmodule
