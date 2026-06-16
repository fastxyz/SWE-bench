requires "mini-logistic-scoring.k"

module LOG-REG-SCORING-SPEC
  imports MINI-LOGISTIC-SCORING

  // SPEC-PROVENANCE:
  // - E2/E3/E4: the scoring estimator must inherit the path parameters.
  // - E7: each candidate score corresponds to the current C.
  claim <k> scoreCandidate(params(P:Int, D:Bool, T:Int, FI:Bool, IS:Int,
                                  CW:Int, RS:Int, S:Int, MI:Int, MC:MultiClass,
                                  V:Int),
                            C:Int, W:Coef, FI)
           => .K ... </k>
        <est> noEstimator
           => estimator(paramsC(P, D, T, FI, IS, CW, RS, S, MI, MC, V, C),
                        coefFor(W, FI),
                        interceptFor(W, FI)) </est>
        [all-path]

  // SPEC-PROVENANCE:
  // - E1/E5/E6: multinomial scorer probabilities must use softmax behavior.
  claim <k> scoreCandidate(params(P:Int, D:Bool, T:Int, FI:Bool, IS:Int,
                                  CW:Int, RS:Int, S:Int, MI:Int, multinomial,
                                  V:Int),
                            C:Int, W:Coef, FI)
           => .K ... </k>
        <branch> noBranch => softmaxBranch </branch>
        [all-path]

  // SPEC-PROVENANCE:
  // - E7: scores are obtained for each C, so every candidate row must be
  //   represented once in the scorer-call stream.
  claim <k> scoreAll(params(P:Int, D:Bool, T:Int, FI:Bool, IS:Int,
                            CW:Int, RS:Int, S:Int, MI:Int, MC:MultiClass,
                            V:Int),
                      CS:CList, WS:WList, FI) => .K ... </k>
        <calls> .CallList
              => expectedCalls(params(P, D, T, FI, IS, CW, RS, S, MI, MC, V),
                               CS, WS, FI) </calls>
        requires sameLength(CS, WS)
        [all-path]
endmodule
