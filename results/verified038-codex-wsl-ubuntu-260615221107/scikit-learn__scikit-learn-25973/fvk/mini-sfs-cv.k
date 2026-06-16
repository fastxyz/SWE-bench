module MINI-SFS-CV-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax Cv ::= "oneShot" "(" Int ")"
              | "iterable" "(" Int ")"
              | "splitter" "(" Int ")"
              | "intCv" "(" Int ")"
              | "noneCv"
              | "checked" "(" Int ")"
              | "emptyCv"
              | "checkCv" "(" Cv ")" [function]

  syntax Result ::= "done" | "failedEmptyScores"

  syntax Stmt ::= "fit" "(" Cv "," Int ")"
                | "rawFit" "(" Cv "," Int ")"
                | "scoreLoop" "(" Int ")"
                | "rawScoreLoop" "(" Int ")"
                | "score"
                | "rawScore"
                | Result

  syntax KResult ::= Cv | Int | Bool | Result
endmodule

module MINI-SFS-CV
  imports MINI-SFS-CV-SYNTAX
  imports INT
  imports BOOL

  configuration
    <k> $PGM:Stmt </k>
    <cv> emptyCv </cv>
    <scores> 0 </scores>

  // Abstraction of sklearn.model_selection.check_cv for the public cv families.
  rule checkCv(oneShot(S:Int)) => checked(S)
  rule checkCv(iterable(S:Int)) => checked(S)
  rule checkCv(splitter(S:Int)) => checked(S)
  rule checkCv(intCv(S:Int)) => checked(S) requires S >=Int 2
  rule checkCv(noneCv) => checked(5)
  rule checkCv(checked(S:Int)) => checked(S)

  // V1 shape: normalize cv once, then reuse that local checked value for all
  // candidate score calls in the fit.
  rule <k> fit(CV:Cv, C:Int) => scoreLoop(C) ... </k>
       <cv> _ => checkCv(CV) </cv>
    requires C >=Int 0

  rule <k> scoreLoop(0) => done ... </k>
  rule <k> scoreLoop(C:Int) => score ~> scoreLoop(C -Int 1) ... </k>
    requires C >Int 0

  rule <k> score => .K ... </k>
       <cv> checked(S:Int) </cv>
       <scores> N:Int => N +Int 1 </scores>
    requires S >Int 0

  // Pre-fix shape used only to localize the reported failure: the same one-shot
  // source is scored repeatedly without prior normalization.
  rule <k> rawFit(CV:Cv, C:Int) => rawScoreLoop(C) ... </k>
       <cv> _ => CV </cv>
    requires C >=Int 0

  rule <k> rawScoreLoop(0) => done ... </k>
  rule <k> rawScoreLoop(C:Int) => rawScore ~> rawScoreLoop(C -Int 1) ... </k>
    requires C >Int 0

  rule <k> rawScore => .K ... </k>
       <cv> oneShot(S:Int) => oneShot(0) </cv>
       <scores> N:Int => N +Int 1 </scores>
    requires S >Int 0

  rule <k> rawScore => failedEmptyScores ... </k>
       <cv> oneShot(0) </cv>

  rule <k> rawScore => .K ... </k>
       <cv> checked(S:Int) </cv>
       <scores> N:Int => N +Int 1 </scores>
    requires S >Int 0
endmodule
