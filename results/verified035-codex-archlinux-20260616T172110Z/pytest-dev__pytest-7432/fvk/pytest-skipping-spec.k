requires "mini-pytest-report.k"

module PYTEST-SKIPPING-SPEC
  imports MINI-PYTEST-REPORT

  // SPEC-PROVENANCE:
  // - from_prompt: "--runxfail is only about xfail and should not affect this"
  //   => marker skip location must be identical with and without runxfail.
  // - from_prompt: expected "test_it.py:3: unconditional skip" rather than
  //   "src/_pytest/skipping.py:238" => internal skip location must be rewritten
  //   to the item location for marked skips.
  // - from_code: reports.py creates skipped reports with the exception raise
  //   site; skipping.py owns the later marker-skip longrepr rewrite.
  claim
    <k> makereport => .K ... </k>
    <runxfail> true </runxfail>
    <unexpected> false </unexpected>
    <when> setupWhen </when>
    <exc> skipExc </exc>
    <xfailed> XF:MaybeXfail => XF </xfailed>
    <skippedbymark> true </skippedbymark>
    <outcome> skippedOutcome => skippedOutcome </outcome>
    <longrepr> internalSkip(R:Reason) => itemSkip(R) </longrepr>
    <wasxfail> W:Bool => W </wasxfail>
    <unexpectedreason> UR:Reason => UR </unexpectedreason>
  [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "--runxfail is only about xfail" => it must not make an
  //   unmarked skip look like a marker skip.
  // - from_code: skipped_by_mark_key distinguishes marker skips from runtime
  //   pytest.skip calls.
  claim
    <k> makereport => .K ... </k>
    <runxfail> true </runxfail>
    <unexpected> false </unexpected>
    <when> setupWhen </when>
    <exc> skipExc </exc>
    <xfailed> XF:MaybeXfail => XF </xfailed>
    <skippedbymark> false </skippedbymark>
    <outcome> skippedOutcome => skippedOutcome </outcome>
    <longrepr> internalSkip(R:Reason) => internalSkip(R) </longrepr>
    <wasxfail> W:Bool => W </wasxfail>
    <unexpectedreason> UR:Reason => UR </unexpectedreason>
  [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "--runxfail is only about xfail" => xfail-specific report
  //   rewrites remain disabled when runxfail is true.
  // - from_code: V1 guards the xfail-exception rewrite with not runxfail.
  claim
    <k> makereport => .K ... </k>
    <runxfail> true </runxfail>
    <unexpected> false </unexpected>
    <when> callWhen </when>
    <exc> xfailExc </exc>
    <xfailed> noXfail </xfailed>
    <skippedbymark> false </skippedbymark>
    <outcome> skippedOutcome => skippedOutcome </outcome>
    <longrepr> internalSkip(R:Reason) => internalSkip(R) </longrepr>
    <wasxfail> W:Bool => W </wasxfail>
    <unexpectedreason> UR:Reason => UR </unexpectedreason>
  [all-path]

  // SPEC-PROVENANCE:
  // - from_code/public behavior: without runxfail, an xfail exception is still
  //   represented as an xfailed skip. V1 must preserve this frame condition.
  claim
    <k> makereport => .K ... </k>
    <runxfail> false </runxfail>
    <unexpected> false </unexpected>
    <when> callWhen </when>
    <exc> xfailExc </exc>
    <xfailed> noXfail </xfailed>
    <skippedbymark> false </skippedbymark>
    <outcome> failedOutcome => skippedOutcome </outcome>
    <longrepr> LR:Longrepr => LR </longrepr>
    <wasxfail> false => true </wasxfail>
    <unexpectedreason> UR:Reason => UR </unexpectedreason>
  [all-path]
endmodule
