module MINI-MIXTURE-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  // Abstract sorts. The mini semantics keeps the property axis visible:
  // labels depend on both X and the current parameter state.
  syntax Data
  syntax Param
  syntax Resp
  syntax Labels
  syntax Run
  syntax Runs ::= ".Runs" | Run ";" Runs [right]

  syntax KItem ::= fitPredict(Runs, Data)
                 | setParams(Param)
                 | finalEStep(Data)
                 | returnLabels(Resp)
                 | predict(Data)
                 | selectBest(Runs, Param, Int)

  syntax Param ::= noParams
                 | paramsOf(Run) [function]
                 | bestParams(Runs) [function]
                 | lastParams(Runs) [function]
                 | bestFrom(Runs, Param, Int) [function]
  syntax Int ::= lowerBound(Run) [function]
               | maxLowerBound(Runs) [function]
  syntax Bool ::= validRuns(Runs) [function]
  syntax Resp ::= eStep(Data, Param) [function]
  syntax Labels ::= argmax(Resp) [function]
                  | labels(Data, Param) [function]
endmodule

module MINI-MIXTURE
  imports MINI-MIXTURE-SYNTAX
  imports INT
  imports BOOL

  configuration
    <k> $PGM:K </k>
    <params> noParams </params>

  // V1 behavior: restore the best parameters before computing the final
  // responsibilities whose argmax is returned.
  rule <k> fitPredict(RS, X) => setParams(bestParams(RS)) ~> finalEStep(X) ... </k>
    requires validRuns(RS)

  rule <k> setParams(P) => .K ... </k>
       <params> _ => P </params>

  rule <k> finalEStep(X) => returnLabels(eStep(X, P)) ... </k>
       <params> P </params>

  rule <k> returnLabels(R) => argmax(R) ... </k>

  rule <k> predict(X) => labels(X, P) ... </k>
       <params> P </params>

  // Shared-state argmax equivalence. In the concrete Python code this follows
  // because log_resp subtracts a single row-wise logsumexp scalar from every
  // component score in that row.
  rule labels(X, P) => argmax(eStep(X, P))

  // Abstract circularity target for best-parameter selection. The spec file
  // states the invariant; this mini fragment does not model floating-point EM.
  rule <k> selectBest(RS, CUR, LB) => bestFrom(RS, CUR, LB) ... </k>
    requires validRuns(RS)
endmodule
