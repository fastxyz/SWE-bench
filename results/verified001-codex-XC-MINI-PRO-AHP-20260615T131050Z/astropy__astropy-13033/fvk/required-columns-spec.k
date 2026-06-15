requires "mini-required-columns.k"

module REQUIRED-COLUMNS-SPEC
  imports MINI-REQUIRED-COLUMNS

  // SPEC-PROVENANCE:
  // - from_intent: disabled required-column checks must not reject the object.
  claim <k> check(C:String, false, REQ:ReqOpt, RELAX:Bool, COLS:Cols)
        => ok(RELAX) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_intent: no required-column contract exists when req is None.
  claim <k> check(C:String, true, none, RELAX:Bool, COLS:Cols)
        => ok(RELAX) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_tests: single-column messages are compatibility behavior.
  claim <k> check(C:String, true, some(REQ:Cols), false, .Cols)
        => error(singleNoColumns(C, head(REQ))) </k>
    requires size(REQ) ==Int 1
    [all-path]

  // SPEC-PROVENANCE:
  // - from_issue: multi-column failures should identify required columns.
  claim <k> check(C:String, true, some(REQ:Cols), false, .Cols)
        => error(multiNoColumns(C, REQ)) </k>
    requires size(REQ) >Int 1
    [all-path]

  // SPEC-PROVENANCE:
  // - from_tests: preserve scalar display for one active required column.
  claim <k> check(C:String, true, some(REQ:Cols), RELAX:Bool, COLS:Cols)
        => error(singleFound(C, head(ACTIVE), head(COLS))) </k>
    requires ACTIVE:Cols ==K activeReq(REQ, RELAX, COLS)
     andBool size(ACTIVE) ==Int 1
     andBool take(COLS, size(ACTIVE)) =/=K ACTIVE
    [all-path]

  // SPEC-PROVENANCE:
  // - from_issue: "required ['time', 'flux'] ... found ['time']".
  claim <k> check(C:String, true, some(REQ:Cols), RELAX:Bool, COLS:Cols)
        => error(multiFound(C, ACTIVE, take(COLS, size(ACTIVE)))) </k>
    requires ACTIVE:Cols ==K activeReq(REQ, RELAX, COLS)
     andBool size(ACTIVE) >Int 1
     andBool take(COLS, size(ACTIVE)) =/=K ACTIVE
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code_comment: relaxed mode turns off once the full prefix is present.
  claim <k> check(C:String, true, some(REQ:Cols), RELAX:Bool, COLS:Cols)
        => ok(RELAX andBool notBool (REQ ==K take(COLS, size(REQ)))) </k>
    requires ACTIVE:Cols ==K activeReq(REQ, RELAX, COLS)
     andBool take(COLS, size(ACTIVE)) ==K ACTIVE
     andBool notBool (notBool RELAX andBool size(COLS) ==Int 0)
    [all-path]
endmodule
