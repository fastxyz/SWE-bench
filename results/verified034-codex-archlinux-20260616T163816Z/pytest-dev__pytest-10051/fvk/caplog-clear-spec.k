requires "mini-caplog.k"

module CAPLOG-CLEAR-SPEC
  imports MINI-CAPLOG
  imports INT
  imports BOOL
  imports LIST
  imports MAP

  // SPEC-PROVENANCE:
  // - INT-1: "caplog.get_records() gets decoupled from actual caplog records
  //   when caplog.clear() is called" => clear must not replace the current
  //   records list object.
  // - INT-2: reproduction asserts get_records("call") == caplog.records before
  //   and after clear => current phase stash and handler records must remain
  //   the same observable list contents.
  // - INT-3: "caplog.clear() ... clear captured records and formatted log
  //   output string" => records and text are empty immediately after clear.
  // CLAIM CLEAR-CURRENT: clearing preserves the current reference R and empties
  // the list object it denotes.
  claim
    <k> caplogClear => .K </k>
    <handlerRef> R:Int </handlerRef>
    <stream> (_:List => .List) </stream>
    <stash> ... P:Phase |-> R ... </stash>
    <heap> ... R |-> (_:List => .List) ... </heap>
    <nextRef> N:Int </nextRef>
    [all-path]

  // SPEC-PROVENANCE:
  // - INT-1 and INT-2 also require that records emitted after clear are visible
  //   through both caplog.records and get_records(P), rather than being appended
  //   only to a replacement list.
  // CLAIM CLEAR-THEN-EMIT: after clear, a later emit appends to the same list
  // object R held by the current phase stash.
  claim
    <k> caplogClear ; emit(B:Int) => .K </k>
    <handlerRef> R:Int </handlerRef>
    <stream> (_:List => ListItem(B)) </stream>
    <stash> ... P:Phase |-> R ... </stash>
    <heap> ... R |-> (_:List => ListItem(B)) ... </heap>
    <nextRef> N:Int </nextRef>
    [all-path]

  // SPEC-PROVENANCE:
  // - INT-4: get_records(when) returns records for one of setup/call/teardown.
  //   Previous phase records must remain available after the handler is reset
  //   for the next phase.
  // - CODE-1: _runtest_for calls reset(), then stores caplog_handler.records in
  //   item.stash[caplog_records_key][when].
  // CLAIM BEGIN-PHASE-PRESERVES-PREVIOUS: beginning the call phase allocates a
  // fresh current list and leaves setup's stored list object unchanged.
  claim
    <k> beginPhase(call) => .K </k>
    <handlerRef> (_:Int => RC:Int) </handlerRef>
    <stream> (_:List => .List) </stream>
    <stash> setup |-> RS:Int => (setup |-> RS call |-> RC) </stash>
    <heap> RS |-> SETUP:List => (RS |-> SETUP RC |-> .List) </heap>
    <nextRef> RC => RC +Int 1 </nextRef>
    requires RS =/=Int RC
    [all-path]
endmodule
