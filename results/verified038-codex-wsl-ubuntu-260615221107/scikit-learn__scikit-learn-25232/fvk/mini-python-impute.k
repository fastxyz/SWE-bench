requires "domains.md"

module MINI-PYTHON-IMPUTE-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax Strategy ::= "mean" | "median" | "most_frequent" | "constant"
  syntax Fill ::= "NoneFill" | "NaNFill" | Int

  syntax FillList ::= ".FillList" | Fill ";" FillList [right]
  syntax IndexList ::= ".IndexList" | Int ";" IndexList [right]

  syntax Obj ::= iterativeObj(Fill)
               | simpleObj(Strategy, Fill)

  syntax KItem ::= initIterative(Fill)
                 | makeInitialImputer(Strategy, Fill)
                 | validMask(Strategy, Int, FillList)
endmodule

module MINI-PYTHON-IMPUTE
  imports MINI-PYTHON-IMPUTE-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:K </k>

  syntax Bool ::= isNaN(Fill) [function]
  rule isNaN(NaNFill) => true
  rule isNaN(NoneFill) => false
  rule isNaN(_:Int) => false

  syntax FillList ::= constantStats(Int, Fill) [function]
  rule constantStats(N, F) => .FillList
    requires N <=Int 0
  rule constantStats(N, F) => F ; constantStats(N -Int 1, F)
    requires N >Int 0

  syntax IndexList ::= allIndices(Int) [function]
  syntax IndexList ::= allIndicesFrom(Int, Int) [function]
  rule allIndices(N) => allIndicesFrom(0, N)
  rule allIndicesFrom(I, N) => .IndexList
    requires I >=Int N
  rule allIndicesFrom(I, N) => I ; allIndicesFrom(I +Int 1, N)
    requires I <Int N

  syntax IndexList ::= nonNanIndices(FillList, Int) [function]
  rule nonNanIndices(.FillList, I) => .IndexList
  rule nonNanIndices(F ; REST, I) => I ; nonNanIndices(REST, I +Int 1)
    requires isNaN(F) ==Bool false
  rule nonNanIndices(F ; REST, I) => nonNanIndices(REST, I +Int 1)
    requires isNaN(F) ==Bool true

  rule <k> initIterative(F) => iterativeObj(F) ... </k>

  rule <k> makeInitialImputer(S, F) => simpleObj(S, F) ... </k>

  rule <k> validMask(constant, N, STATS) => allIndices(N) ... </k>
    requires N >=Int 0

  rule <k> validMask(mean, N, STATS) => nonNanIndices(STATS, 0) ... </k>
    requires N >=Int 0

  rule <k> validMask(median, N, STATS) => nonNanIndices(STATS, 0) ... </k>
    requires N >=Int 0

  rule <k> validMask(most_frequent, N, STATS) => nonNanIndices(STATS, 0) ... </k>
    requires N >=Int 0
endmodule

