requires "mini-python-refit.k"

module SEARCHCV-REFIT-SPEC
  imports MINI-PYTHON-REFIT
  imports INT
  imports BOOL

  // SPEC-PROVENANCE:
  // - E1/E2/E3: prompt requests an attribute `refit_time_` for the time to
  //   refit the best model on full data after grid/random search.
  // - E6/E8: refit means the final full-data fit; existing timing convention
  //   starts after parameter assignment and before estimator.fit.
  // - E9: all candidate-search state is framed and unchanged.
  claim [refitTrue]:
    <k> fitTail(true, HASY:Bool) => .K ... </k>
    <bestEstimator> absentEstimator => fittedEstimator </bestEstimator>
    <refitTime> absentInt => TEnd:Int -Int TStart:Int </refitTime>
    <fitSawY> absentBool => HASY </fitSawY>
    <startSample> absentInt => TStart </startSample>
    <clockStart> TStart </clockStart>
    <clockEnd> TEnd </clockEnd>
    <cvState> CV:Int </cvState>
    requires TEnd >=Int TStart
    [all-path]

  // SPEC-PROVENANCE:
  // - E6: with refit=False there is no final refit and no best_estimator_.
  // - Default-domain assumption: `refit_time_` follows the same availability
  //   pattern as the refitted estimator.
  claim [refitFalse]:
    <k> fitTail(false, HASY:Bool) => .K ... </k>
    <bestEstimator> BE:EstimatorState </bestEstimator>
    <refitTime> RT:MaybeInt </refitTime>
    <fitSawY> FY:MaybeBool </fitSawY>
    <startSample> SS:MaybeInt </startSample>
    <clockStart> TStart:Int </clockStart>
    <clockEnd> TEnd:Int </clockEnd>
    <cvState> CV:Int </cvState>
    [all-path]
endmodule
