requires "mini-python-count-vectorizer.k"

module MINI-CV-SPEC
  imports MINI-CV
  imports BOOL
  imports MAP
  imports LIST

  // SPEC-PROVENANCE:
  // - E-001/E-002/E-003: a valid constructor vocabulary should make
  //   get_feature_names usable before fit, by the same lazy validation path
  //   as transform.
  // - E-004: valid constructor vocabularies are non-empty and normalize to
  //   unique, gapless feature indices.
  // - E-005: the observable result is the names ordered by feature index.
  // PO-001-fixed-vocabulary-unfitted
  claim
    <k> getFeatureNames => .K </k>
    <cv-param> P:VocabParam </cv-param>
    <has-vocabulary> false => true </has-vocabulary>
    <vocabulary> _ => normalizeVocab(P) </vocabulary>
    <has-fixed> _ => true </has-fixed>
    <fixed> _ => true </fixed>
    <result> noResult => featureList(orderByIndex(normalizeVocab(P))) </result>
    <exception> noException </exception>
    requires P =/=K noneVocab
     andBool validVocab(P)
     andBool notBool emptyVocab(normalizeVocab(P))
    [all-path]

  // SPEC-PROVENANCE:
  // - E-005: once vocabulary_ exists, get_feature_names returns names ordered
  //   by feature integer index.
  // PO-002-existing-vocabulary
  claim
    <k> getFeatureNames => .K </k>
    <cv-param> P:VocabParam </cv-param>
    <has-vocabulary> true </has-vocabulary>
    <vocabulary> V:Map </vocabulary>
    <has-fixed> HF:Bool </has-fixed>
    <fixed> F:Bool </fixed>
    <result> noResult => featureList(orderByIndex(V)) </result>
    <exception> noException </exception>
    requires notBool emptyVocab(V)
    [all-path]

  // SPEC-PROVENANCE:
  // - E-006: an unfitted vectorizer without a constructor vocabulary remains
  //   not fitted and raises NotFittedError for vocabulary-dependent methods.
  // - The final fixed_vocabulary_ side effect is intentionally unconstrained;
  //   it is not part of public intent.
  // PO-003-no-vocabulary-unfitted
  claim
    <k> getFeatureNames => .K </k>
    <cv-param> noneVocab </cv-param>
    <has-vocabulary> false </has-vocabulary>
    <vocabulary> V:Map </vocabulary>
    <has-fixed> HF:Bool => ?HFOut:Bool </has-fixed>
    <fixed> F:Bool => ?FOut:Bool </fixed>
    <result> noResult </result>
    <exception> noException => notFittedError </exception>
    [all-path]

  // SPEC-PROVENANCE:
  // - E-004: invalid constructor vocabularies remain rejected by the existing
  //   validation path.
  // PO-004-invalid-constructor-vocabulary
  claim
    <k> getFeatureNames => .K </k>
    <cv-param> P:VocabParam </cv-param>
    <has-vocabulary> false </has-vocabulary>
    <vocabulary> V:Map </vocabulary>
    <result> noResult </result>
    <exception> noException => valueError </exception>
    requires P =/=K noneVocab
     andBool (notBool validVocab(P)
              orBool emptyVocab(normalizeVocab(P)))
    [all-path]
endmodule
