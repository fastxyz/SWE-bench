requires "mini-logregcv.k"

module LOGREGCV-REFIT-FALSE-SPEC
  imports MINI-LOGREGCV

  // SPEC-PROVENANCE:
  // - from_issue: "IndexError thrown with LogisticRegressionCV and refit=False"
  // - from_issue: default multi_class='auto', binary data, solver='saga'
  // - from_docstring: auto selects OvR for binary data
  // - from_code: resolved local multi_class controls coefficient-path rank
  claim <k> noRefitStep(auto, otherSolver, 2, rank3, nonElasticnet, false) => ok </k>
    [label(AUTO-OVR-NO-INDEX-ERROR)]

  // SPEC-PROVENANCE:
  // - from_issue: "same error with 'liblinear'"
  // - from_docstring: auto selects OvR if solver='liblinear'
  claim <k> noRefitStep(auto, liblinear, 3, rank3, nonElasticnet, false) => ok </k>
    [label(LIBLINEAR-AUTO-OVR-NO-INDEX-ERROR)]

  // SPEC-PROVENANCE:
  // - from_docstring: auto selects multinomial for non-liblinear multiclass
  // - from_code: multinomial coefficient path keeps class axis
  claim <k> noRefitStep(auto, otherSolver, 3, rank4, nonElasticnet, false) => ok </k>
    [label(MULTINOMIAL-INDEX-OK)]

  // SPEC-PROVENANCE:
  // - from_docstring: l1_ratios is only used for penalty='elasticnet'
  // - from_docstring: if no l1 ratio is used, l1_ratios_ is [None]
  claim <k> selectL1(nonElasticnet, true) => noneL1 </k>
    [label(NON-ELASTICNET-L1-ABSENT)]

  // SPEC-PROVENANCE:
  // - from_docstring: l1_ratios is list-like for elastic-net
  // - from_code: np.asarray allows fold-index array selection
  claim <k> selectL1(elasticnet, true) => meanL1 </k>
    [label(ELASTICNET-L1-MEAN-OK)]

  // SPEC-PROVENANCE:
  // - from_docstring: coefs_paths_/scores_ gain l1 dimension if penalty='elasticnet'
  // - from_docstring: l1_ratios ignored for non-elastic-net penalties
  claim <k> shapeFor(nonElasticnet) => plainShape </k>
    [label(SHAPE-PLAIN-WHEN-NON-ELASTICNET)]

  claim <k> shapeFor(elasticnet) => elasticnetShape </k>
    [label(SHAPE-ELASTICNET-WHEN-ELASTICNET)]
endmodule
