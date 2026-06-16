requires "mini-sklearn-clone.k"

module MINI-SKLEARN-CLONE-SPEC
  imports MINI-SKLEARN-CLONE

  // SPEC-PROVENANCE:
  // - from_prompt: "clone fails when one or more instance parameters are
  //   estimator types (i.e. not instances, but classes)" => a class-valued
  //   parameter is in domain.
  // - from_prompt: "Expected Results: No error." => recursive parameter clone
  //   must not invoke an unbound get_params method on the class.
  // - from_hint: "not isinstance(obj, type) might be" => classes are not
  //   estimator instances for this guard.
  claim
    <k> CloneParam(classObj(C:Id), false)
      => ObjResult(classObj(C)) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_hint: "We need to support non-estimators with get_params, such as
  //   Kernel, so isinstance(obj, BaseEstimator) is not appropriate" => non-class
  //   get_params-bearing objects remain estimator-like for clone.
  claim
    <k> CloneParam(kernelObj(K:Id, P:Map), false)
      => EstimatorClone(kernelObj(K, P)) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: BaseEstimator.get_params(deep=True) returns nested parameters
  //   for contained estimator subobjects.
  // - from_prompt/hint: estimator classes are types, not estimator instances.
  //   They should be included as ordinary parameter values, not expanded.
  claim
    <k> DeepParamEntry(PNAME:Id, classObj(C:Id))
      => IncludeOnly(PNAME, classObj(C)) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_api: _BaseComposition backs public get_params(deep=True) on
  //   Pipeline, FeatureUnion, and VotingClassifier named estimators.
  // - from_prompt/hint: class-valued parameters must not be treated as nested
  //   estimator instances merely because they expose get_params.
  claim
    <k> CompositionEntry(NAME:Id, classObj(C:Id))
      => IncludeOnly(NAME, classObj(C)) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_clone_docstring: clone takes estimator objects or containers of
  //   estimator objects.
  // - from_baseline_decision: a class passed directly with safe=True remains
  //   outside the estimator-instance domain and follows the existing error path.
  claim
    <k> CloneParam(classObj(C:Id), true)
      => TypeError </k>
    [all-path]
endmodule
