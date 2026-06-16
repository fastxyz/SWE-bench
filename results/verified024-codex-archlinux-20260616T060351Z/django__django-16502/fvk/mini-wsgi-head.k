module MINI-WSGI-HEAD-SYNTAX
  imports INT
  imports BOOL

  syntax Method ::= "GET" | "HEAD" | "OTHER"
  syntax Bytes ::= bytes(Int)
  syntax Chunks ::= ".Chunks" | Bytes Chunks
  syntax KItem ::= write(Bytes) | sendfile | finishHead | finishContent | close
endmodule

module MINI-WSGI-HEAD
  imports MINI-WSGI-HEAD-SYNTAX

  configuration
    <T>
      <k> $PGM:K </k>
      <method> GET </method>
      <status> true </status>
      <headersSent> false </headersSent>
      <bytesSent> 0 </bytesSent>
      <stdoutBytes> 0 </stdoutBytes>
      <flushed> false </flushed>
      <closed> false </closed>
      <resultClosed> false </resultClosed>
      <sendfileUsed> false </sendfileUsed>
      <result> .Chunks </result>
    </T>

  // HEAD write: header bookkeeping may change, but response body output does not.
  rule <k> write(bytes(N)) => . ... </k>
       <method> HEAD </method>
       <status> true </status>
       <headersSent> false => true </headersSent>
       <bytesSent> _ => N </bytesSent>
       <stdoutBytes> OUT => OUT </stdoutBytes>
       <flushed> _ => true </flushed>
    requires N >=Int 0

  rule <k> write(bytes(N)) => . ... </k>
       <method> HEAD </method>
       <status> true </status>
       <headersSent> true </headersSent>
       <bytesSent> B => B +Int N </bytesSent>
       <stdoutBytes> OUT => OUT </stdoutBytes>
    requires N >=Int 0

  // Non-HEAD write is included only as a frame contrast for the changed path.
  rule <k> write(bytes(N)) => . ... </k>
       <method> M </method>
       <status> true </status>
       <headersSent> false => true </headersSent>
       <bytesSent> _ => N </bytesSent>
       <stdoutBytes> OUT => OUT +Int N </stdoutBytes>
       <flushed> _ => true </flushed>
    requires M =/=K HEAD andBool N >=Int 0

  rule <k> sendfile => . ... </k>
       <method> HEAD </method>
       <sendfileUsed> _ => false </sendfileUsed>
       <stdoutBytes> OUT => OUT </stdoutBytes>

  // HEAD finish consumes at most the first chunk to establish headers, then
  // finishes/flushed/closes without body output.
  rule <k> finishHead => write(bytes(N)) ~> finishContent ~> close ... </k>
       <method> HEAD </method>
       <result> bytes(N) REST => REST </result>
    requires N >=Int 0

  rule <k> finishHead => finishContent ~> close ... </k>
       <method> HEAD </method>
       <result> .Chunks </result>

  rule <k> finishContent => . ... </k>
       <headersSent> false => true </headersSent>
       <flushed> _ => true </flushed>
       <stdoutBytes> OUT => OUT </stdoutBytes>

  rule <k> finishContent => . ... </k>
       <headersSent> true </headersSent>
       <flushed> _ => true </flushed>
       <stdoutBytes> OUT => OUT </stdoutBytes>

  rule <k> close => . ... </k>
       <closed> _ => true </closed>
       <resultClosed> _ => true </resultClosed>
endmodule
