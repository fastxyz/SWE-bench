requires "mini-sfs-cv.k"

module SFS-CV-SPEC
  imports MINI-SFS-CV

  // SPEC-PROVENANCE:
  // - E2/E3/E8: repeated candidate scoring must reuse checked splits.
  // - from_code: V1 passes the local checked cv into every cross_val_score call.
  claim
    <k> scoreLoop(C:Int) => done ... </k>
    <cv> checked(S:Int) </cv>
    <scores> N:Int => N +Int C </scores>
    requires S >Int 0 andBool C >=Int 0
    [all-path, label(SFS-SCORE-LOOP)]

  // SPEC-PROVENANCE:
  // - E1/E2: generator-like splits passed as cv must work in one SFS fit.
  // - E4/E8: check_cv materializes iterables into a reusable checked object.
  claim
    <k> fit(oneShot(S:Int), C:Int) => done ... </k>
    <cv> emptyCv => checked(S) </cv>
    <scores> 0 => C </scores>
    requires S >Int 0 andBool C >=Int 0
    [all-path, label(SFS-FIT-ONESHOT)]

  // SPEC-PROVENANCE:
  // - E5/E6/E7: non-string iterable cv inputs remain valid.
  claim
    <k> fit(iterable(S:Int), C:Int) => done ... </k>
    <cv> emptyCv => checked(S) </cv>
    <scores> 0 => C </scores>
    requires S >Int 0 andBool C >=Int 0
    [all-path, label(SFS-FIT-ITERABLE)]

  // SPEC-PROVENANCE:
  // - E5/E6: CV splitter objects remain valid and reusable.
  claim
    <k> fit(splitter(S:Int), C:Int) => done ... </k>
    <cv> emptyCv => checked(S) </cv>
    <scores> 0 => C </scores>
    requires S >Int 0 andBool C >=Int 0
    [all-path, label(SFS-FIT-SPLITTER)]

  // SPEC-PROVENANCE:
  // - E5/E6: integer cv values remain valid and preserve their fold count.
  claim
    <k> fit(intCv(S:Int), C:Int) => done ... </k>
    <cv> emptyCv => checked(S) </cv>
    <scores> 0 => C </scores>
    requires S >=Int 2 andBool C >=Int 0
    [all-path, label(SFS-FIT-INT)]

  // SPEC-PROVENANCE:
  // - E5/E8: None follows check_cv's default five-fold behavior.
  claim
    <k> fit(noneCv, C:Int) => done ... </k>
    <cv> emptyCv => checked(5) </cv>
    <scores> 0 => C </scores>
    requires C >=Int 0
    [all-path, label(SFS-FIT-NONE)]

  // SPEC-PROVENANCE:
  // - E3: this localizes the legacy failure; it is not intended behavior.
  claim
    <k> rawFit(oneShot(S:Int), C:Int) => failedEmptyScores ... </k>
    <cv> emptyCv => oneShot(0) </cv>
    requires S >Int 0 andBool C >=Int 2
    [one-path, label(SFS-RAW-ONESHOT-FAILS)]
endmodule
