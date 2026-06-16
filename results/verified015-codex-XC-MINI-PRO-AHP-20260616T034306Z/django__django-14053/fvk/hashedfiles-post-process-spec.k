requires "mini-python.k"

module HASHEDFILES-POST-PROCESS-SPEC-SYNTAX
  imports MINI-PYTHON-STATICFILES-SYNTAX
endmodule

module HASHEDFILES-POST-PROCESS-VERIFICATION
  imports MINI-PYTHON-STATICFILES
  imports HASHEDFILES-POST-PROCESS-SPEC-SYNTAX
  imports BOOL
  imports LIST
  imports MAP

  syntax Bool ::= noErrors(List) [function]
                | noErrorsPasses(List) [function]
                | stableBeforeMax(List) [function]
                | uniqueNames(List) [function]

  syntax List ::= firstNonAdjustOut(List) [function]
                | finalAdjustOut(List, List) [function]
                | outputNames(List) [function]
                | append(List, List) [function]

  syntax Map ::= finalDeferred(List, List) [function]
endmodule

module HASHEDFILES-POST-PROCESS-SPEC
  imports HASHEDFILES-POST-PROCESS-VERIFICATION

  // SPEC-PROVENANCE:
  // - from_problem: "post_process() returns (via yield) the same original
  //   filename multiple times" => successful yields must be unique by original.
  // - from_problem: "intermediate files ... shouldn't be passed back" =>
  //   adjustable pass outputs are buffered and only the final one is emitted.
  // - from_code: _post_process is abstracted as FIRST/PASSES event lists.
  claim [POST-PROCESS-SUCCESS]:
    <k> emitPostProcess(FIRST:List, PASSES:List, false) => .K </k>
    <deferred> .Map => finalDeferred(FIRST, PASSES) </deferred>
    <out> .List => append(firstNonAdjustOut(FIRST), finalAdjustOut(FIRST, PASSES)) </out>
    requires noErrors(FIRST)
     andBool noErrorsPasses(PASSES)
     andBool stableBeforeMax(PASSES)
    ensures uniqueNames(outputNames(append(firstNonAdjustOut(FIRST), finalAdjustOut(FIRST, PASSES))))
    [all-path]

  // SPEC-PROVENANCE:
  // - from_collectstatic: exception tuples are raised as soon as collectstatic
  //   sees them, so post_process must not defer them.
  claim [POST-PROCESS-FIRST-PASS-ERROR]:
    <k> emitPostProcess(PREFIX:List ListItem(ex(N:String)) REST:List, PASSES:List, MAX:Bool) => .K </k>
    <out> .List => append(firstNonAdjustOut(PREFIX), ListItem(err(N))) </out>
    requires noErrors(PREFIX)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_collectstatic: exception tuples are raised immediately.
  // - from_problem: buffered adjustable pass details are not public successes.
  claim [POST-PROCESS-REPEAT-PASS-ERROR]:
    <k> emitPostProcess(FIRST:List, PREFIXPASSES:List ListItem(PREFIX:List ListItem(ex(N:String)) RESTPASS:List) RESTPASSES:List, MAX:Bool) => .K </k>
    <out> .List => append(firstNonAdjustOut(FIRST), ListItem(err(N))) </out>
    requires noErrors(FIRST)
     andBool noErrorsPasses(PREFIXPASSES)
     andBool noErrors(PREFIX)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_problem: max-pass failure is an error path, not a successful reason
  //   to expose intermediate adjustable files.
  // - from_code: V1 preserves the existing "All" error tuple.
  claim [POST-PROCESS-MAX-ERROR]:
    <k> emitPostProcess(FIRST:List, PASSES:List, true) => .K </k>
    <out> .List => append(firstNonAdjustOut(FIRST), ListItem(err("All"))) </out>
    requires noErrors(FIRST)
     andBool noErrorsPasses(PASSES)
    [all-path]
endmodule
