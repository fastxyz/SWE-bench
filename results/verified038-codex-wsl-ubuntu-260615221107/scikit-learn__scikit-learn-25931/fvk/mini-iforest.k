module MINI-IFOREST-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports LIST-SYNTAX

  syntax Input ::= df(Int) | arr(Int) | csc(Int) | csr(Int)
  syntax VX ::= dense(Int) | fitCsc(Int) | scoreCsr(Int)
  syntax Contam ::= auto | fixed(Int)
  syntax Warn ::= invalidFeatureNames
  syntax Score ::= noOffset | autoOffset | raw(VX) | percentile(Score, Int)

  syntax Stmt ::= fit(Input, Contam)
                | validateFit(Input)
                | finishFit(Contam)
                | publicScoreSamples(Input)
                | validateScore(Input)
                | finishPublicScore
                | privateScoreSamples(VX)
                | setOffsetFromScore(Int)

  syntax KResult ::= VX | Score
endmodule

module MINI-IFOREST
  imports MINI-IFOREST-SYNTAX
  imports INT
  imports BOOL
  imports LIST

  configuration
    <k> $PGM:Stmt </k>
    <fitted> false </fitted>
    <namesSeen> false </namesSeen>
    <warnings> .List </warnings>
    <offset> noOffset </offset>

  // fit performs the reset=True validation first, then computes the branch.
  rule <k> fit(X:Input, C:Contam) => validateFit(X) ~> finishFit(C) ... </k>

  // A DataFrame with valid string columns records feature names and becomes
  // the internal dense representation used by the forest.
  rule <k> validateFit(df(N:Int)) => dense(N) ... </k>
       <namesSeen> _ => true </namesSeen>

  // Arrays have no feature names.
  rule <k> validateFit(arr(N:Int)) => dense(N) ... </k>
       <namesSeen> _ => false </namesSeen>

  // Sparse fit data is normalized to the fitting representation.
  rule <k> validateFit(csc(N:Int)) => fitCsc(N) ... </k>
       <namesSeen> _ => false </namesSeen>
  rule <k> validateFit(csr(N:Int)) => fitCsc(N) ... </k>
       <namesSeen> _ => false </namesSeen>

  // auto contamination does not score training data to define offset.
  rule <k> V:VX ~> finishFit(auto) => .K ... </k>
       <offset> _ => autoOffset </offset>
       <fitted> _ => true </fitted>

  // fixed contamination uses the private scorer on the already validated X.
  rule <k> V:VX ~> finishFit(fixed(C:Int))
        => privateScoreSamples(V) ~> setOffsetFromScore(C) ... </k>

  rule <k> S:Score ~> setOffsetFromScore(C:Int) => .K ... </k>
       <offset> _ => percentile(S, C) </offset>
       <fitted> _ => true </fitted>

  // Public score_samples still validates user input with reset=False.
  rule <k> publicScoreSamples(X:Input)
        => validateScore(X) ~> finishPublicScore ... </k>

  rule <k> validateScore(df(N:Int)) => dense(N) ... </k>
       <namesSeen> true </namesSeen>

  rule <k> validateScore(arr(N:Int)) => dense(N) ... </k>
       <namesSeen> true </namesSeen>
       <warnings> W:List => W ListItem(invalidFeatureNames) </warnings>

  rule <k> validateScore(arr(N:Int)) => dense(N) ... </k>
       <namesSeen> false </namesSeen>

  rule <k> validateScore(csc(N:Int)) => scoreCsr(N) ... </k>
  rule <k> validateScore(csr(N:Int)) => scoreCsr(N) ... </k>

  rule <k> V:VX ~> finishPublicScore => privateScoreSamples(V) ... </k>

  // Private score_samples computes scores without feature-name validation.
  rule <k> privateScoreSamples(dense(N:Int)) => raw(dense(N)) ... </k>
  rule <k> privateScoreSamples(scoreCsr(N:Int)) => raw(scoreCsr(N)) ... </k>

  // fit validates sparse input as CSC, but scoring must use CSR.
  rule <k> privateScoreSamples(fitCsc(N:Int)) => raw(scoreCsr(N)) ... </k>
endmodule
