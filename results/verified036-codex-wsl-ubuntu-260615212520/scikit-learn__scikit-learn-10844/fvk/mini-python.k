module MINI-PYTHON-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax Score ::= zeroScore()
                 | ratio(Int, Int)
                 | sqrtScore(Score)
                 | mulScore(Score, Score)
                 | expectedFmi(Int, Int, Int)

  syntax Exp ::= fmi(Int, Int, Int)

  syntax KResult ::= Score
endmodule

module MINI-PYTHON
  imports MINI-PYTHON-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:Exp </k>

  // Reduced in-domain arithmetic kernel for the final fowlkes_mallows_score
  // return expression. It models the V1 source expression:
  //   sqrt(tk / pk) * sqrt(tk / qk) if tk != 0 else 0
  rule <k> fmi(0, PK:Int, QK:Int) => zeroScore() </k>
    requires PK >=Int 0 andBool QK >=Int 0

  rule <k> fmi(TK:Int, PK:Int, QK:Int)
        => mulScore(sqrtScore(ratio(TK, PK)), sqrtScore(ratio(TK, QK))) </k>
    requires TK =/=Int 0
endmodule
