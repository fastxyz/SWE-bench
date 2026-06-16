// Constructed FVK artifact for scikit-learn__scikit-learn-14629.
// Commands to machine-check later, not executed in this environment:
//   cd fvk
//   kompile mini-python.k --backend haskell
//   kast --backend haskell multioutput-classes-spec.k
//   kprove multioutput-classes-spec.k

requires "mini-python.k"

module MINI-PYTHON-MULTIOUTPUT-SPEC-SYNTAX
  imports MINI-PYTHON-MULTIOUTPUT-SYNTAX
endmodule

module VERIFICATION
  imports MINI-PYTHON-MULTIOUTPUT
  imports MINI-PYTHON-MULTIOUTPUT-SPEC-SYNTAX
  imports LIST
  imports MAP
  imports K-EQUAL

  // The list comprehension [estimator.classes_ for estimator in estimators_]
  // is exactly the inverse of the abstract fit construction.
  rule classesFromEstimators(estimatorsFromClasses(CS:List)) => CS
    [simplification]
endmodule

module MULTIOUTPUT-CLASSES-SPEC
  imports VERIFICATION

  // SPEC-PROVENANCE:
  // - from_prompt: "All classifiers should store `classes_` when fitted."
  //   => fitted MultiOutputClassifier has classes_.
  // - from_prompt: "add `classes_` to `MultiOutputClassifier` like it is in
  //   `ClassifierChain`" => classes_ is per-output and aligned with estimators_.
  // - from_code: inherited fit constructs estimators_; V1 assigns classes_ by
  //   reading each fitted estimator.classes_.
  claim
    <k> moc_fit(SELF:Id, CS:List) => .K ... </k>
    <store> SELF |-> (_ => MOC(estimatorsFromClasses(CS), CS)) </store>
    requires size(CS) >=Int 1
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "All classifiers should store `classes_` when fitted."
  //   => successful incremental fitting should expose the same fitted
  //   classifier attribute.
  // - from_code: V1 partial_fit delegates to the shared implementation, then
  //   assigns classes_ from each fitted estimator.
  claim
    <k> moc_partial_fit(SELF:Id, CS:List) => .K ... </k>
    <store> SELF |-> (_ => MOC(estimatorsFromClasses(CS), CS)) </store>
    requires size(CS) >=Int 1
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: cross_val_predict(method='predict_proba') with
  //   MultiOutputClassifier should return prediction probabilities instead of
  //   AttributeError.
  // - from_code: _fit_and_predict indexes estimator.classes_[i_label] for
  //   list-valued predictions; V1 makes that indexed list available.
  claim
    <k> moc_fit(SELF:Id, CS:List)
        ~> cvp_predict_proba(SELF, PREDS:List) => .K ... </k>
    <store> SELF |-> (_ => MOC(estimatorsFromClasses(CS), CS))
            result |-> (_ => enforceListOrder(CS, PREDS)) </store>
    requires size(CS) >=Int 1
      andBool size(CS) ==Int size(PREDS)
    [all-path]
endmodule
