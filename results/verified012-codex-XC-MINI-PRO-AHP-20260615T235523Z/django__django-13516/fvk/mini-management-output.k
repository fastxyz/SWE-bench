module MINI-MANAGEMENT-OUTPUT-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports ID-SYNTAX

  syntax Ret ::= Int | "none"
  syntax StreamState ::= "stream" "(" Bool "," Int "," Int "," Int "," Ret ")"
  syntax Wrapper ::= "wrapper" "(" Id ")"
  syntax Stmt ::= Wrapper ".flush" "(" ")"
                | Wrapper ".writePartial" "(" Int ")"
  syntax KResult ::= Ret
endmodule

module MINI-MANAGEMENT-OUTPUT
  imports MINI-MANAGEMENT-OUTPUT-SYNTAX
  imports INT
  imports BOOL
  imports MAP

  configuration
    <k> $PGM:Stmt </k>
    <streams> .Map </streams>

  // Abstract model of OutputWrapper.write(..., ending=""): bytes/chars are
  // buffered on the wrapped stream but are not visible until the stream flushes.
  rule <k> wrapper(O:Id).writePartial(N:Int) => .K ... </k>
       <streams>
         ... O |-> (stream(H:Bool, B:Int, V:Int, F:Int, R:Ret)
                    => stream(H, B +Int N, V, F, R)) ...
       </streams>
    requires N >=Int 0

  // Abstract model of V1 OutputWrapper.flush(): if the wrapped stream supports
  // flush, delegate to it and return its value.
  rule <k> wrapper(O:Id).flush() => R ... </k>
       <streams>
         ... O |-> (stream(true, B:Int, V:Int, F:Int, R:Ret)
                    => stream(true, 0, V +Int B, F +Int 1, R)) ...
       </streams>
    requires B >=Int 0

  // Compatibility branch for stream-like objects with write() but no flush().
  rule <k> wrapper(O:Id).flush() => none ... </k>
       <streams> ... O |-> stream(false, B:Int, V:Int, F:Int, R:Ret) ... </streams>
    requires B >=Int 0
endmodule
