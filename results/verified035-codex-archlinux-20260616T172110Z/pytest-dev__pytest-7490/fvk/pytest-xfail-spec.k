requires "mini-pytest-xfail.k"

module PYTEST-XFAIL-SPEC
  imports MINI-PYTEST-XFAIL

  // SPEC-PROVENANCE:
  // - from_prompt: "request.node.add_marker(mark)" followed by "assert 0"
  //   should be treated like an xfail-marked failing test.
  // - from_prompt: expected short summary shows "XFAIL ... xfail".
  // - from_code: V1 refreshes cached xfail state when xfail marker count
  //   changes before marker-based call report handling.
  claim
    <k> setupEval ~> callStart ~> addXfail(xfailReason) ~> failCall ~> makeCallReport => .K </k>
    <markers> 0 => 1 </markers>
    <active> noXfail => xfail(xfailReason, true, false, anyRaises) </active>
    <cache> noXfail => xfail(xfailReason, true, false, anyRaises) </cache>
    <cacheCount> -1 => 1 </cacheCount>
    <callFailed> false => true </callFailed>
    <callPassed> false </callPassed>
    <repSkipped> false </repSkipped>
    <explicitXfail> false </explicitXfail>
    <runxfail> false </runxfail>
    <report> noReport => skipped </report>
    <wasxfail> noWasXfail => wasXfail(xfailReason) </wasxfail>
    [label(dynamic_xfail_body), all-path]

  // SPEC-PROVENANCE:
  // - from_code/docs: `raises` mismatch on xfail remains a true failure.
  // - from_code: V1 only refreshes the xfail cache, then reuses existing
  //   marker report logic.
  claim
    <k> addXfailMismatch(xfailReason) ~> failCall ~> makeCallReport => .K </k>
    <markers> 0 => 1 </markers>
    <active> noXfail => xfail(xfailReason, true, false, mismatchRaises) </active>
    <cache> noXfail => xfail(xfailReason, true, false, mismatchRaises) </cache>
    <cacheCount> 0 => 1 </cacheCount>
    <callFailed> false => true </callFailed>
    <repSkipped> false </repSkipped>
    <explicitXfail> false </explicitXfail>
    <runxfail> false </runxfail>
    <report> noReport => failed </report>
    [label(dynamic_xfail_raises_mismatch), all-path]

  // SPEC-PROVENANCE:
  // - from_code/docs: non-strict XPASS remains passed with wasxfail.
  // - from_code: V1 refreshes marker state and reuses existing pass branch.
  claim
    <k> addXfail(xfailReason) ~> passCall ~> makeCallReport => .K </k>
    <markers> 0 => 1 </markers>
    <active> noXfail => xfail(xfailReason, true, false, anyRaises) </active>
    <cache> noXfail => xfail(xfailReason, true, false, anyRaises) </cache>
    <cacheCount> 0 => 1 </cacheCount>
    <callFailed> false </callFailed>
    <callPassed> false => true </callPassed>
    <repSkipped> false </repSkipped>
    <explicitXfail> false </explicitXfail>
    <runxfail> false </runxfail>
    <report> noReport => passed </report>
    <wasxfail> noWasXfail => wasXfail(xfailReason) </wasxfail>
    [label(dynamic_xfail_xpass), all-path]
endmodule
