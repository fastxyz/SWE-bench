requires "mini-mixture.k"

module MIXTURE-FIT-PREDICT-SPEC
  imports MINI-MIXTURE

  // SPEC-PROVENANCE:
  // - from_prompt: "predict and fit_predict disagree when n_init>1"
  //   => returned labels must come from the fitted best-parameter state.
  // - from_hint: final self._e_step() should occur after
  //   self._set_parameters(best_params).
  // - from_docstring: fit_predict sets parameters with largest likelihood or
  //   lower bound, then predicts labels.
  // - from_code: eStep and predict both read current estimator parameters.
  claim
    <k> fitPredict(RS:Runs, X:Data) => labels(X, bestParams(RS)) ... </k>
    <params> noParams => bestParams(RS) </params>
    requires validRuns(RS)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docstring: the selected fitted parameters are those with largest
  //   likelihood or lower bound across n_init runs.
  // - from_code: BaseMixture updates best_params only when
  //   lower_bound > max_lower_bound.
  claim
    <k> selectBest(RS:Runs, CUR:Param, LB:Int)
      => bestFrom(RS, CUR, LB) ... </k>
    requires validRuns(RS)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_test_comment: fit_predict(X) is equivalent to
  //   fit(X).predict(X).
  // - from_code: log_resp is weighted_log_prob minus one scalar per row, so
  //   per-row argmax is preserved.
  claim
    <k> returnLabels(eStep(X:Data, P:Param)) => labels(X, P) ... </k>
    [all-path]
endmodule
