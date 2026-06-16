module MINI-PYTEST-XFAIL-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax Reason ::= xfailReason
  syntax RaisesMode ::= anyRaises | mismatchRaises
  syntax XfailState ::= noXfail | xfail(Reason, Bool, Bool, RaisesMode)
  syntax Outcome ::= noReport | passed | failed | skipped
  syntax WasXfail ::= noWasXfail | wasXfail(Reason)

  syntax KItem ::= setupEval
                 | callStart
                 | addXfail(Reason)
                 | addXfailMismatch(Reason)
                 | failCall
                 | passCall
                 | skipCall
                 | imperativeXfail
                 | makeCallReport

  syntax KResult ::= XfailState | Outcome | WasXfail
endmodule

module MINI-PYTEST-XFAIL
  imports MINI-PYTEST-XFAIL-SYNTAX
  imports INT
  imports BOOL

  configuration
    <k> $PGM:K </k>
    <markers> 0 </markers>
    <active> noXfail </active>
    <cache> noXfail </cache>
    <cacheCount> -1 </cacheCount>
    <callFailed> false </callFailed>
    <callPassed> false </callPassed>
    <repSkipped> false </repSkipped>
    <explicitXfail> false </explicitXfail>
    <runxfail> false </runxfail>
    <report> noReport </report>
    <wasxfail> noWasXfail </wasxfail>

  // Public marker API effect for the issue path: one visible active xfail.
  rule <k> addXfail(R) => .K ... </k>
       <markers> M => M +Int 1 </markers>
       <active> _ => xfail(R, true, false, anyRaises) </active>

  rule <k> addXfailMismatch(R) => .K ... </k>
       <markers> M => M +Int 1 </markers>
       <active> _ => xfail(R, true, false, mismatchRaises) </active>

  // Cache xfail state during setup when xfail handling is enabled.
  rule <k> setupEval => .K ... </k>
       <runxfail> false </runxfail>
       <markers> M </markers>
       <active> XF </active>
       <cache> _ => XF </cache>
       <cacheCount> _ => M </cacheCount>

  // V1 preserves the previous call-start refresh when cached xfail is None.
  rule <k> callStart => .K ... </k>
       <markers> M </markers>
       <active> XF </active>
       <cache> noXfail => XF </cache>
       <cacheCount> _ => M </cacheCount>

  // V1 also refreshes at call start when marker count changed.
  rule <k> callStart => .K ... </k>
       <markers> M </markers>
       <active> XF </active>
       <cache> _ => XF </cache>
       <cacheCount> C => M </cacheCount>
    requires C =/=Int M

  rule <k> failCall => .K ... </k>
       <callFailed> false => true </callFailed>

  rule <k> passCall => .K ... </k>
       <callPassed> false => true </callPassed>

  rule <k> skipCall => .K ... </k>
       <repSkipped> false => true </repSkipped>
       <report> _ => skipped </report>

  rule <k> imperativeXfail => .K ... </k>
       <explicitXfail> false => true </explicitXfail>

  // Report-time refresh for body-time marker additions, then failure xfail.
  rule <k> makeCallReport => .K ... </k>
       <runxfail> false </runxfail>
       <explicitXfail> false </explicitXfail>
       <repSkipped> false </repSkipped>
       <callFailed> true </callFailed>
       <markers> M </markers>
       <active> xfail(R, RUN, STRICT, anyRaises) </active>
       <cache> _ => xfail(R, RUN, STRICT, anyRaises) </cache>
       <cacheCount> C => M </cacheCount>
       <report> _ => skipped </report>
       <wasxfail> _ => wasXfail(R) </wasxfail>
    requires C =/=Int M

  // Existing raises mismatch behavior is preserved after refresh.
  rule <k> makeCallReport => .K ... </k>
       <runxfail> false </runxfail>
       <explicitXfail> false </explicitXfail>
       <repSkipped> false </repSkipped>
       <callFailed> true </callFailed>
       <markers> M </markers>
       <active> xfail(R, RUN, STRICT, mismatchRaises) </active>
       <cache> _ => xfail(R, RUN, STRICT, mismatchRaises) </cache>
       <cacheCount> C => M </cacheCount>
       <report> _ => failed </report>
    requires C =/=Int M

  // Existing non-strict XPASS behavior is preserved after refresh.
  rule <k> makeCallReport => .K ... </k>
       <runxfail> false </runxfail>
       <explicitXfail> false </explicitXfail>
       <repSkipped> false </repSkipped>
       <callPassed> true </callPassed>
       <markers> M </markers>
       <active> xfail(R, RUN, false, anyRaises) </active>
       <cache> _ => xfail(R, RUN, false, anyRaises) </cache>
       <cacheCount> C => M </cacheCount>
       <report> _ => passed </report>
       <wasxfail> _ => wasXfail(R) </wasxfail>
    requires C =/=Int M

  // Existing strict XPASS behavior is preserved after refresh.
  rule <k> makeCallReport => .K ... </k>
       <runxfail> false </runxfail>
       <explicitXfail> false </explicitXfail>
       <repSkipped> false </repSkipped>
       <callPassed> true </callPassed>
       <markers> M </markers>
       <active> xfail(R, RUN, true, anyRaises) </active>
       <cache> _ => xfail(R, RUN, true, anyRaises) </cache>
       <cacheCount> C => M </cacheCount>
       <report> _ => failed </report>
    requires C =/=Int M
endmodule
