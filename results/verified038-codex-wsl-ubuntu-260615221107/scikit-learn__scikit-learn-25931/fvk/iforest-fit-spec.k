requires "mini-iforest.k"

module MINI-IFOREST-SPEC
  imports MINI-IFOREST
  imports INT
  imports BOOL
  imports LIST

  // SPEC-PROVENANCE:
  // - from_prompt: DataFrame fit with contamination != "auto" must not emit
  //   "X does not have valid feature names..." during fit.
  // - from_prompt: root cause is public score_samples revalidating an array
  //   after fit recorded feature names.
  // - from_code: V1 fit calls private _score_samples on the already validated X.
  claim
    <k> fit(df(N:Int), fixed(C:Int)) => .K ... </k>
    <namesSeen> false => true </namesSeen>
    <warnings> .List => .List </warnings>
    <offset> noOffset => percentile(raw(dense(N)), C) </offset>
    <fitted> false => true </fitted>
    requires N >Int 0 andBool C >Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: non-auto contamination defines offset from training scores.
  // - from_code: the numerical raw score is unchanged and abstracted as raw(V).
  claim
    <k> privateScoreSamples(dense(N:Int)) ~> setOffsetFromScore(C:Int)
        => .K ... </k>
    <warnings> .List => .List </warnings>
    <offset> noOffset => percentile(raw(dense(N)), C) </offset>
    requires N >Int 0 andBool C >Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_base_tests: public methods with reset=False warn when an estimator
  //   fitted with feature names receives array input with no names.
  // - from_code: public score_samples still validates before private scoring.
  claim
    <k> publicScoreSamples(arr(N:Int)) => raw(dense(N)) ... </k>
    <namesSeen> true </namesSeen>
    <warnings> .List => ListItem(invalidFeatureNames) </warnings>
    <fitted> true </fitted>
    requires N >Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: DataFrame inputs have valid feature names.
  // - from_code: public score_samples validates matching feature names and then
  //   delegates to the private scorer.
  claim
    <k> publicScoreSamples(df(N:Int)) => raw(dense(N)) ... </k>
    <namesSeen> true </namesSeen>
    <warnings> .List => .List </warnings>
    <fitted> true </fitted>
    requires N >Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: contamination == "auto" sets offset to the fixed auto value.
  // - from_code: this branch returns before training-data scoring.
  claim
    <k> fit(df(N:Int), auto) => .K ... </k>
    <namesSeen> false => true </namesSeen>
    <warnings> .List => .List </warnings>
    <offset> noOffset => autoOffset </offset>
    <fitted> false => true </fitted>
    requires N >Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs/tests: sparse input is supported.
  // - from_tree_code: scoring tree.apply expects CSR when validation is
  //   bypassed.
  // - from_code: V1 private scorer converts sparse fitting data to CSR.
  claim
    <k> fit(csc(N:Int), fixed(C:Int)) => .K ... </k>
    <namesSeen> false => false </namesSeen>
    <warnings> .List => .List </warnings>
    <offset> noOffset => percentile(raw(scoreCsr(N)), C) </offset>
    <fitted> false => true </fitted>
    requires N >Int 0 andBool C >Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: private scoring path exists specifically to avoid
  //   user-input feature-name validation inside fit.
  claim
    <k> privateScoreSamples(dense(N:Int)) => raw(dense(N)) ... </k>
    <namesSeen> true </namesSeen>
    <warnings> .List => .List </warnings>
    requires N >Int 0
    [all-path]
endmodule
