// Minimal K-style semantics fragment for the pytest fd-capture audit.
// Constructed, not machine-checked in this environment.

module MINI-CAPTURE-SYNTAX
  syntax NewlineMode ::= "Translate" | "Preserve"
  syntax Bytes ::= ".Bytes" | "bytes" "(" String ")"
  syntax Text ::= String
  syntax Command ::= "snapText" | "snapBytes"
endmodule

module MINI-CAPTURE
  imports MINI-CAPTURE-SYNTAX

  configuration
    <k> $PGM:Command </k>
    <tmp> .Bytes </tmp>
    <newline> Preserve </newline>
    <textResult> "" </textResult>
    <bytesResult> .Bytes </bytesResult>

  // decodePreserve models io.TextIOWrapper(newline="").read():
  // bytes are decoded with the configured codec/error policy, and line-ending
  // characters are returned unchanged.
  syntax Text ::= decodePreserve(Bytes) [function]
  rule decodePreserve(bytes(S:String)) => S

  rule <k> snapText => .K </k>
       <tmp> B:Bytes => .Bytes </tmp>
       <newline> Preserve </newline>
       <textResult> _ => decodePreserve(B) </textResult>

  rule <k> snapBytes => .K </k>
       <tmp> B:Bytes => .Bytes </tmp>
       <bytesResult> _ => B </bytesResult>
endmodule
