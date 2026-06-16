module MINI-PYTEST-REPORT-SYNTAX
  imports BOOL-SYNTAX

  syntax Action ::= "makereport"
                  | "checkUnexpected"
                  | "checkXfailException"
                  | "checkXfailed"
                  | "checkMarkedSkip"
                  | "done"

  syntax Outcome ::= "passedOutcome" | "failedOutcome" | "skippedOutcome"
  syntax When ::= "setupWhen" | "callWhen" | "teardownWhen"
  syntax ExcKind ::= "noExc" | "skipExc" | "xfailExc" | "otherExc"
  syntax MaybeXfail ::= "noXfail" | "xfailRun" | "xfailStrict" | "xfailNonStrict"
  syntax Reason ::= "reason" | "unexpectedReason"
  syntax Longrepr ::= "noneLongrepr"
                    | "internalSkip" "(" Reason ")"
                    | "itemSkip" "(" Reason ")"
                    | "unexpectedLongrepr" "(" Reason ")"
                    | "strictXpass" "(" Reason ")"
                    | "otherLongrepr"

  syntax KResult ::= Outcome | When | ExcKind | MaybeXfail | Reason | Longrepr | Bool
endmodule

module MINI-PYTEST-REPORT
  imports MINI-PYTEST-REPORT-SYNTAX
  imports BOOL

  configuration
    <k> $PGM:Action </k>
    <runxfail> false </runxfail>
    <unexpected> false </unexpected>
    <when> setupWhen </when>
    <exc> noExc </exc>
    <xfailed> noXfail </xfailed>
    <skippedbymark> false </skippedbymark>
    <outcome> passedOutcome </outcome>
    <longrepr> noneLongrepr </longrepr>
    <wasxfail> false </wasxfail>
    <unexpectedreason> unexpectedReason </unexpectedreason>

  rule <k> makereport => checkUnexpected ... </k>

  // First branch: unittest unexpected-success special case.
  rule <k> checkUnexpected => done ... </k>
       <unexpected> true </unexpected>
       <when> callWhen </when>
       <unexpectedreason> R:Reason </unexpectedreason>
       <outcome> _O:Outcome => failedOutcome </outcome>
       <longrepr> _LR:Longrepr => unexpectedLongrepr(R) </longrepr>

  rule <k> checkUnexpected => checkXfailException ... </k>
       <unexpected> false </unexpected>
  rule <k> checkUnexpected => checkXfailException ... </k>
       <unexpected> true </unexpected>
       <when> setupWhen </when>
  rule <k> checkUnexpected => checkXfailException ... </k>
       <unexpected> true </unexpected>
       <when> teardownWhen </when>

  // V2 behavior: runxfail disables only xfail-specific rewrites.
  rule <k> checkXfailException => checkXfailed ... </k>
       <runxfail> true </runxfail>

  rule <k> checkXfailException => done ... </k>
       <runxfail> false </runxfail>
       <exc> xfailExc </exc>
       <outcome> _O:Outcome => skippedOutcome </outcome>
       <wasxfail> _W:Bool => true </wasxfail>

  rule <k> checkXfailException => checkXfailed ... </k>
       <runxfail> false </runxfail>
       <exc> noExc </exc>
  rule <k> checkXfailException => checkXfailed ... </k>
       <runxfail> false </runxfail>
       <exc> skipExc </exc>
  rule <k> checkXfailException => checkXfailed ... </k>
       <runxfail> false </runxfail>
       <exc> otherExc </exc>

  rule <k> checkXfailed => checkMarkedSkip ... </k>
       <runxfail> true </runxfail>
  rule <k> checkXfailed => checkMarkedSkip ... </k>
       <runxfail> false </runxfail>
       <xfailed> noXfail </xfailed>

  // Reduced model of the non-runxfail xfailed branch. It exists here only as a
  // frame condition for the guard changed in src/_pytest/skipping.py.
  rule <k> checkXfailed => done ... </k>
       <runxfail> false </runxfail>
       <xfailed> xfailStrict </xfailed>
       <when> callWhen </when>
       <exc> noExc </exc>
       <outcome> _O:Outcome => failedOutcome </outcome>
       <longrepr> _LR:Longrepr => strictXpass(reason) </longrepr>

  rule <k> checkXfailed => done ... </k>
       <runxfail> false </runxfail>
       <xfailed> xfailNonStrict </xfailed>
       <when> callWhen </when>
       <exc> noExc </exc>
       <outcome> _O:Outcome => passedOutcome </outcome>
       <wasxfail> _W:Bool => true </wasxfail>

  rule <k> checkXfailed => done ... </k>
       <runxfail> false </runxfail>
       <xfailed> xfailRun </xfailed>
       <exc> otherExc </exc>
       <outcome> _O:Outcome => skippedOutcome </outcome>
       <wasxfail> _W:Bool => true </wasxfail>

  // Marker-skip location rewrite. This is intentionally after the runxfail
  // xfail guards, matching the patched hook's branch order.
  rule <k> checkMarkedSkip => done ... </k>
       <skippedbymark> true </skippedbymark>
       <outcome> skippedOutcome </outcome>
       <longrepr> internalSkip(R:Reason) => itemSkip(R) </longrepr>

  rule <k> checkMarkedSkip => done ... </k>
       <skippedbymark> false </skippedbymark>
  rule <k> checkMarkedSkip => done ... </k>
       <skippedbymark> true </skippedbymark>
       <outcome> passedOutcome </outcome>
  rule <k> checkMarkedSkip => done ... </k>
       <skippedbymark> true </skippedbymark>
       <outcome> failedOutcome </outcome>
  rule <k> checkMarkedSkip => done ... </k>
       <skippedbymark> true </skippedbymark>
       <outcome> skippedOutcome </outcome>
       <longrepr> itemSkip(_R:Reason) </longrepr>
  rule <k> checkMarkedSkip => done ... </k>
       <skippedbymark> true </skippedbymark>
       <outcome> skippedOutcome </outcome>
       <longrepr> noneLongrepr </longrepr>
  rule <k> checkMarkedSkip => done ... </k>
       <skippedbymark> true </skippedbymark>
       <outcome> skippedOutcome </outcome>
       <longrepr> otherLongrepr </longrepr>

  rule <k> done => .K ... </k>
endmodule
