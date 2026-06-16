requires "mini-hgb-scorer.k"

module HGB-SCORER-SPEC
  imports MINI-HGB-SCORER

  // SPEC-PROVENANCE:
  // - E7: scorer y must match public prediction labels.
  // - I4: regression/base targets have no class-code/public-label split.
  claim
    <k> getYForScorer(base, CLASSES:Labels, Y:YVec) => Y ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E1/E2/E3: classifier early stopping with string labels must not compare
  //   internal integer y_true against public string y_pred.
  // - E4/E5/E6: encoded classifier targets map back through classes_.
  claim
    <k> getYForScorer(classifier, CLASSES:Labels, codes(YS:Codes))
        => labels(decode(CLASSES, YS)) ... </k>
    requires validCodes(CLASSES, YS)
    [all-path]

  // SPEC-PROVENANCE:
  // - I2/I5: with validation data, both scorer calls get public classifier labels.
  claim
    <k> checkEarlyStoppingScorer(classifier, CLASSES:Labels,
                                 codes(YTRAIN:Codes), codes(YVAL:Codes), true)
        => .K </k>
    <trainArg> _ => labels(decode(CLASSES, YTRAIN)) </trainArg>
    <validationArg> _ => labels(decode(CLASSES, YVAL)) </validationArg>
    <validationUsed> _ => true </validationUsed>
    requires validCodes(CLASSES, YTRAIN) andBool validCodes(CLASSES, YVAL)
    [all-path]

  // SPEC-PROVENANCE:
  // - I2/I5: without validation data, the training scorer gets public
  //   classifier labels and no validation scorer is made.
  claim
    <k> checkEarlyStoppingScorer(classifier, CLASSES:Labels,
                                 codes(YTRAIN:Codes), YVAL:YVec, false)
        => .K </k>
    <trainArg> _ => labels(decode(CLASSES, YTRAIN)) </trainArg>
    <validationArg> V:YVec => V </validationArg>
    <validationUsed> _ => false </validationUsed>
    requires validCodes(CLASSES, YTRAIN)
    [all-path]

  // SPEC-PROVENANCE:
  // - I4/I5: base/regression scorer targets are preserved when validation is used.
  claim
    <k> checkEarlyStoppingScorer(base, CLASSES:Labels,
                                 YTRAIN:YVec, YVAL:YVec, true)
        => .K </k>
    <trainArg> _ => YTRAIN </trainArg>
    <validationArg> _ => YVAL </validationArg>
    <validationUsed> _ => true </validationUsed>
    [all-path]

  // SPEC-PROVENANCE:
  // - I4/I5: base/regression scorer targets are preserved for train-only scoring.
  claim
    <k> checkEarlyStoppingScorer(base, CLASSES:Labels,
                                 YTRAIN:YVec, YVAL:YVec, false)
        => .K </k>
    <trainArg> _ => YTRAIN </trainArg>
    <validationArg> V:YVec => V </validationArg>
    <validationUsed> _ => false </validationUsed>
    [all-path]
endmodule
