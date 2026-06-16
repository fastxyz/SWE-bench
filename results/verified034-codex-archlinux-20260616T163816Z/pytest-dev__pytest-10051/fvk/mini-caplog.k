module MINI-CAPLOG-SYNTAX
  imports INT-SYNTAX

  syntax Phase ::= "setup" | "call" | "teardown"
  syntax Cmd ::= "emit" "(" Int ")"             [strict]
               | "caplogClear"
               | "beginPhase" "(" Phase ")"
               | Cmd ";" Cmd                    [left]
endmodule

module MINI-CAPLOG
  imports MINI-CAPLOG-SYNTAX
  imports INT
  imports BOOL
  imports LIST
  imports MAP

  configuration
    <k> $PGM:Cmd </k>
    <handlerRef> 0 </handlerRef>
    <stream> .List </stream>
    <stash> .Map </stash>
    <heap> .Map </heap>
    <nextRef> 1 </nextRef>

  rule <k> C1:Cmd ; C2:Cmd => C1 ~> C2 ... </k>

  // Model LogCaptureHandler.emit: append to the list object referenced by
  // handler.records and append to the formatted stream.
  rule <k> emit(R:Int) => .K ... </k>
       <handlerRef> H:Int </handlerRef>
       <stream> T:List => T ListItem(R) </stream>
       <heap> ... H |-> (L:List => L ListItem(R)) ... </heap>

  // Model LogCaptureHandler.clear from V1: clear the current records list
  // object in place and clear the text stream.
  rule <k> caplogClear => .K ... </k>
       <handlerRef> H:Int </handlerRef>
       <stream> _:List => .List </stream>
       <heap> ... H |-> (_:List => .List) ... </heap>

  // Model the phase transition in LoggingPlugin._runtest_for:
  // reset allocates a fresh list object, then the phase stash records that
  // object. Existing phase references and their list contents are preserved.
  rule <k> beginPhase(P:Phase) => .K ... </k>
       <handlerRef> _ => N </handlerRef>
       <stream> _ => .List </stream>
       <stash> ST:Map => ST [ P <- N ] </stash>
       <heap> HEAP:Map => HEAP [ N <- .List ] </heap>
       <nextRef> N => N +Int 1 </nextRef>
    requires notBool (N in_keys(HEAP))
endmodule
