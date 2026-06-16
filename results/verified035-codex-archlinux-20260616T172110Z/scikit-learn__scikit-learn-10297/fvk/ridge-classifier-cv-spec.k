requires "mini-python.k"

module RIDGE-CLASSIFIER-CV-SPEC
  imports MINI-PYTHON

  // SPEC-PROVENANCE:
  // - from_prompt: "Add store_cv_values boolean flag support to RidgeClassifierCV"
  //   => constructor accepts and stores the flag.
  // - from_docs: "Cross-validation values ... if store_cv_values=True and cv=None"
  //   => the flag controls cv_values_ availability after fit.
  claim
    <k> constructRidgeClassifierCV(STORE:Bool, CVNONE:Bool)
      => rcvcv(STORE, CVNONE, false) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "Expected ... keeping the cross validation predictions as attribute"
  // - from_code: _BaseRidgeCV.fit copies estimator.cv_values_ when self.store_cv_values.
  claim
    <k> fitRidgeClassifierCV(rcvcv(true, true, false))
      => rcvcv(true, true, true) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: store_cv_values default is false; cv_values_ is optional.
  // - from_compatibility: omitted parameter preserves pre-existing default behavior.
  claim
    <k> fitRidgeClassifierCV(rcvcv(false, CVNONE:Bool, false))
      => rcvcv(false, CVNONE, false) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: "This flag is only compatible with cv=None"
  // - from_code: _BaseRidgeCV.fit raises ValueError when cv!=None and
  //   store_cv_values=True.
  claim
    <k> fitRidgeClassifierCV(rcvcv(true, false, false))
      => incompatibleCV </k>
    [all-path]
endmodule
