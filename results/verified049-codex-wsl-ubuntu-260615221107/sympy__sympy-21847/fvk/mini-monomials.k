requires "domains.md"

module MINI-MONOMIALS-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports LIST-SYNTAX

  syntax ExpCounts ::= counts(List)

  syntax Int ::= totalDegree(ExpCounts) [function]
               | maxExponent(ExpCounts) [function]
               | maxInt(Int, Int) [function]

  syntax Bool ::= acceptByTotal(ExpCounts, Int) [function]
                | acceptByMax(ExpCounts, Int) [function]
                | unitBranchYieldsOne(Int) [function]
endmodule

module MINI-MONOMIALS
  imports MINI-MONOMIALS-SYNTAX
  imports INT
  imports BOOL
  imports LIST

  configuration <k> $PGM:K </k>

  rule totalDegree(counts(.List)) => 0
  rule totalDegree(counts(ListItem(E:Int) ES:List))
    => E +Int totalDegree(counts(ES))

  rule maxExponent(counts(.List)) => 0
  rule maxExponent(counts(ListItem(E:Int) ES:List))
    => maxInt(E, maxExponent(counts(ES)))

  rule maxInt(A:Int, B:Int) => A requires A >=Int B
  rule maxInt(A:Int, B:Int) => B requires A <Int B

  rule acceptByTotal(CS:ExpCounts, MIN:Int)
    => totalDegree(CS) >=Int MIN
    requires MIN >=Int 0

  rule acceptByMax(CS:ExpCounts, MIN:Int)
    => maxExponent(CS) >=Int MIN
    requires MIN >=Int 0

  rule unitBranchYieldsOne(MIN:Int) => MIN ==Int 0
    requires MIN >=Int 0
endmodule
