requires "mini-python.k"

module VOTING-FIT-SPEC
  imports MINI-PYTHON-VOTING

  // SPEC-PROVENANCE:
  // - from_prompt: "Voting estimator will fail at fit if weights are passed
  //   and an estimator is None" => a dropped estimator is in-domain for fit.
  // - from_prompt: "Because we don't check for an estimator to be `None` in
  //   `sample_weight` support" => sample_weight support is checked only for
  //   active non-dropped estimators.
  // - from_docs: "estimators_ ... that are not `None`" => fitted estimator
  //   names and fit calls range over active(ES).
  claim [FIT-SAMPLE-WEIGHT-ACTIVE]:
    <k> fitVoting(ES:Ests, true)
      => ok(names(active(ES)), names(active(ES)))
    </k>
    requires notBool isEmpty(active(ES))
     andBool notBool hasUnsupported(active(ES))
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt example: set_params(lr=None) then fit(..., sample_weight=...)
  //   should no longer inspect or fit the dropped lr estimator.
  claim [FIT-REPORTED-EXAMPLE]:
    <k> fitVoting(est(lr, true, true) ;; est(rf, false, true) ;; .Ests, true)
      => ok(rf :: .Names, rf :: .Names)
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from public test test_sample_weight: an active estimator that lacks
  //   sample_weight support still raises the existing unsupported-estimator
  //   error. Dropped estimators are excluded by active(ES).
  claim [FIT-ACTIVE-UNSUPPORTED]:
    <k> fitVoting(ES:Ests, true)
      => errorUnsupported(firstUnsupported(active(ES)))
    </k>
    requires notBool isEmpty(active(ES))
     andBool hasUnsupported(active(ES))
    [all-path]

  // SPEC-PROVENANCE:
  // - from public test test_set_estimator_none: all estimators set to None
  //   raises "All estimators are None. At least one is required!".
  claim [FIT-ALL-DROPPED]:
    <k> fitVoting(ES:Ests, SW:Bool) => errorAllNone </k>
    requires isEmpty(active(ES))
    [all-path]

  // SPEC-PROVENANCE:
  // - from existing fit behavior and docstring: without sample_weight, fit
  //   skips support checks and fits only active estimators.
  claim [FIT-NO-SAMPLE-WEIGHT]:
    <k> fitVoting(ES:Ests, false)
      => ok(names(active(ES)), names(active(ES)))
    </k>
    requires notBool isEmpty(active(ES))
    [all-path]
endmodule
