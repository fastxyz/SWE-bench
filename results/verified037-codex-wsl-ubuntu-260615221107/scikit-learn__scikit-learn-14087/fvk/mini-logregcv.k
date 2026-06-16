module MINI-LOGREGCV-SYNTAX
  imports INT
  imports BOOL

  syntax Mode ::= "ovr" | "multinomial" | "auto"
  syntax Solver ::= "liblinear" | "otherSolver"
  syntax Penalty ::= "elasticnet" | "nonElasticnet"
  syntax Rank ::= "rank3" | "rank4"
  syntax Branch ::= "ovrBranch" | "multinomialBranch"
  syntax L1Result ::= "noneL1" | "meanL1"
  syntax ShapeResult ::= "plainShape" | "elasticnetShape"
  syntax Result ::= "ok" | "indexError" | "l1Error" | "shapeError"

  syntax Mode ::= resolve(Mode, Solver, Int) [function]
  syntax Branch ::= branchFor(Mode) [function]
  syntax Bool ::= indexingOk(Branch, Rank) [function]
  syntax L1Result ::= selectL1(Penalty, Bool) [function]
  syntax Bool ::= l1Ok(Penalty, Bool) [function]
  syntax ShapeResult ::= shapeFor(Penalty) [function]
  syntax Result ::= noRefitStep(Mode, Solver, Int, Rank, Penalty, Bool) [function]
endmodule

module MINI-LOGREGCV
  imports MINI-LOGREGCV-SYNTAX

  configuration <k> $PGM:K </k>

  rule resolve(auto, liblinear, N) => ovr
  rule resolve(auto, otherSolver, N) => ovr requires N <=Int 2
  rule resolve(auto, otherSolver, N) => multinomial requires N >Int 2
  rule resolve(ovr, S, N) => ovr
  rule resolve(multinomial, S, N) => multinomial

  rule branchFor(ovr) => ovrBranch
  rule branchFor(multinomial) => multinomialBranch

  rule indexingOk(ovrBranch, rank3) => true
  rule indexingOk(ovrBranch, rank4) => false
  rule indexingOk(multinomialBranch, rank3) => false
  rule indexingOk(multinomialBranch, rank4) => true

  rule selectL1(elasticnet, ISLIST:Bool) => meanL1
  rule selectL1(nonElasticnet, ISLIST:Bool) => noneL1

  rule l1Ok(elasticnet, ISLIST:Bool) => true
  rule l1Ok(nonElasticnet, ISLIST:Bool) => true

  rule shapeFor(elasticnet) => elasticnetShape
  rule shapeFor(nonElasticnet) => plainShape

  rule noRefitStep(M, S, N, R, P, L) => ok
    requires indexingOk(branchFor(resolve(M, S, N)), R) ==Bool true
     andBool l1Ok(P, L) ==Bool true
endmodule
