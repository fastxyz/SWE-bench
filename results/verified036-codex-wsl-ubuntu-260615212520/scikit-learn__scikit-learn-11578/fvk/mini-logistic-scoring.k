module MINI-LOGISTIC-SCORING-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax MultiClass ::= "ovr" | "multinomial"
  syntax Branch ::= "ovrBranch" | "softmaxBranch" | "noBranch"

  // Non-boolean constructor parameters are abstract Int tokens. The proof only
  // needs equality preservation, not their concrete domains.
  syntax Params ::= params(Int, Bool, Int, Bool, Int, Int, Int, Int, Int, MultiClass, Int)
  syntax ParamsC ::= paramsC(Int, Bool, Int, Bool, Int, Int, Int, Int, Int, MultiClass, Int, Int)

  syntax Coef ::= coef(Int) | coefOvr(Coef) | coefMain(Coef) | coefNoIntercept(Coef)
  syntax Intercept ::= interceptOf(Coef) | zeroIntercept
  syntax Estimator ::= noEstimator | estimator(ParamsC, Coef, Intercept)

  syntax CList ::= ".CList" | ccons(Int, CList)
  syntax WList ::= ".WList" | wcons(Coef, WList)
  syntax CallList ::= ".CallList" | callcons(Estimator, Branch, CallList)

  syntax Cmd ::= scoreCandidate(Params, Int, Coef, Bool)
               | scoreAll(Params, CList, WList, Bool)
endmodule

module MINI-LOGISTIC-SCORING
  imports MINI-LOGISTIC-SCORING-SYNTAX
  imports INT
  imports BOOL

  configuration
    <k> $PGM:Cmd </k>
    <est> noEstimator </est>
    <branch> noBranch </branch>
    <calls> .CallList </calls>

  syntax ParamsC ::= withC(Params, Int) [function]
  rule withC(params(P, D, T, FI, IS, CW, RS, S, MI, MC, V), C)
    => paramsC(P, D, T, FI, IS, CW, RS, S, MI, MC, V, C)

  syntax MultiClass ::= multiClassOf(Params) [function]
  rule multiClassOf(params(P, D, T, FI, IS, CW, RS, S, MI, MC, V)) => MC

  syntax Branch ::= branchOf(MultiClass) [function]
  rule branchOf(ovr) => ovrBranch
  rule branchOf(multinomial) => softmaxBranch

  syntax Coef ::= coefFor(Coef, Bool) [function]
  rule coefFor(W, true) => coefMain(W)
  rule coefFor(W, false) => coefNoIntercept(W)

  syntax Intercept ::= interceptFor(Coef, Bool) [function]
  rule interceptFor(W, true) => interceptOf(W)
  rule interceptFor(W, false) => zeroIntercept

  syntax CallList ::= expectedCalls(Params, CList, WList, Bool) [function]
  rule expectedCalls(P, .CList, .WList, FI) => .CallList
  rule expectedCalls(P, ccons(C, CS), wcons(W, WS), FI)
    => callcons(estimator(withC(P, C), coefFor(W, FI), interceptFor(W, FI)),
                branchOf(multiClassOf(P)),
                expectedCalls(P, CS, WS, FI))

  syntax CallList ::= appendCall(CallList, Estimator, Branch) [function]
  rule appendCall(.CallList, E, B) => callcons(E, B, .CallList)
  rule appendCall(callcons(E0, B0, REST), E, B)
    => callcons(E0, B0, appendCall(REST, E, B))

  syntax Bool ::= sameLength(CList, WList) [function]
  rule sameLength(.CList, .WList) => true
  rule sameLength(ccons(C, CS), wcons(W, WS)) => sameLength(CS, WS)
  rule sameLength(.CList, wcons(W, WS)) => false
  rule sameLength(ccons(C, CS), .WList) => false

  rule <k> scoreCandidate(P, C, W, FI) => .K </k>
       <est> _ => estimator(withC(P, C), coefFor(W, FI), interceptFor(W, FI)) </est>
       <branch> _ => branchOf(multiClassOf(P)) </branch>

  rule <k> scoreAll(P, .CList, .WList, FI) => .K </k>

  rule <k> scoreAll(P, ccons(C, CS), wcons(W, WS), FI)
        => scoreAll(P, CS, WS, FI) </k>
       <calls> OLD => appendCall(OLD,
                                 estimator(withC(P, C), coefFor(W, FI), interceptFor(W, FI)),
                                 branchOf(multiClassOf(P))) </calls>
endmodule
