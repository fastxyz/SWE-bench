module MINI-CAPTURE-SYNTAX
  imports BOOL

  // A tiny abstraction of Python file mode strings for this issue.
  // mcB is the binary flag "b"; every other constructor is non-binary.
  syntax ModeChar ::= "mcR" | "mcW" | "mcA" | "mcPlus" | "mcT" | "mcU" | "mcOther"
  syntax ModeChar ::= "mcB"
  syntax Mode ::= ".Mode" | ModeChar Mode

  syntax Mode ::= stripB(Mode) [function, total]
  syntax Bool ::= hasB(Mode) [function, total]

  syntax KItem ::= encodedFileMode(Mode)
                 | encodedFileBufferMode(Mode)
endmodule

module MINI-CAPTURE
  imports MINI-CAPTURE-SYNTAX

  configuration <k> $PGM:K </k>
                <bufferMode> .Mode </bufferMode>

  rule stripB(.Mode) => .Mode
  rule stripB(mcB M) => stripB(M)
  rule stripB(mcR M) => mcR stripB(M)
  rule stripB(mcW M) => mcW stripB(M)
  rule stripB(mcA M) => mcA stripB(M)
  rule stripB(mcPlus M) => mcPlus stripB(M)
  rule stripB(mcT M) => mcT stripB(M)
  rule stripB(mcU M) => mcU stripB(M)
  rule stripB(mcOther M) => mcOther stripB(M)

  rule hasB(.Mode) => false
  rule hasB(mcB M) => true
  rule hasB(mcR M) => hasB(M)
  rule hasB(mcW M) => hasB(M)
  rule hasB(mcA M) => hasB(M)
  rule hasB(mcPlus M) => hasB(M)
  rule hasB(mcT M) => hasB(M)
  rule hasB(mcU M) => hasB(M)
  rule hasB(mcOther M) => hasB(M)

  // EncodedFile.mode in V1 reads the wrapped buffer mode and strips "b".
  rule <k> encodedFileMode(M) => stripB(M) ... </k>
       <bufferMode> M </bufferMode>

  // The underlying stream remains available through EncodedFile.buffer.mode.
  rule <k> encodedFileBufferMode(M) => M ... </k>
       <bufferMode> M </bufferMode>
endmodule
