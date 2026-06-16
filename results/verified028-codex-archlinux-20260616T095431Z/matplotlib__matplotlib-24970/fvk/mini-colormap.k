module MINI-COLORMAP-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax Cmd ::= "normalizeIndex" "(" Int "," Int "," Bool "," Int ")"
  syntax KResult ::= Int | Bool
endmodule

module MINI-COLORMAP
  imports MINI-COLORMAP-SYNTAX
  imports INT
  imports BOOL

  configuration
    <k> $PGM:Cmd </k>
    <result> 0 </result>

  // Abstracts the V1 dtype-capacity branch:
  // keep CAP when it can represent B, otherwise promote to a capacity >= B.
  syntax Int ::= "ensureCapacity" "(" Int "," Int ")" [function]
  rule ensureCapacity(B, CAP) => CAP requires B <=Int CAP
  rule ensureCapacity(B, CAP) => B requires B >Int CAP

  syntax Int ::= "normIndex" "(" Int "," Int "," Bool ")" [function]
  rule normIndex(N, V, true) => N +Int 2
  rule normIndex(N, V, false) => N +Int 1
    requires V >Int N -Int 1
  rule normIndex(N, V, false) => N
    requires V <=Int N -Int 1 andBool V <Int 0
  rule normIndex(N, V, false) => V
    requires V <=Int N -Int 1 andBool 0 <=Int V

  rule
    <k> normalizeIndex(N, V, BAD, CAP) => .K </k>
    <result> _ => normIndex(N, V, BAD) </result>
    requires ensureCapacity(N +Int 2, CAP) >=Int N +Int 2
endmodule
