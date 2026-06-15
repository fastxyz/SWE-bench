module MINI-UFUNC-DISPATCH-SYNTAX
  imports BOOL-SYNTAX

  syntax Obj ::= "Q" | "ND" | "NONE" | "OTHER_UNIT" | "OTHER_PLAIN"
  syntax Objs ::= ".Objs" | Obj "," Objs [right]
  syntax Decision ::= "PROCEED" | "NOT_IMPLEMENTED"
  syntax Pgm ::= "quantityArrayUfunc" "(" Objs ";" Objs ")"
  syntax KResult ::= Decision
endmodule

module MINI-UFUNC-DISPATCH
  imports MINI-UFUNC-DISPATCH-SYNTAX
  imports BOOL

  configuration <k> $PGM:Pgm </k>

  syntax Objs ::= "concat" "(" Objs ";" Objs ")" [function]
  rule concat(.Objs ; OS) => OS
  rule concat(O:Obj , IS ; OS) => O , concat(IS ; OS)

  syntax Bool ::= "hasUnsupported" "(" Objs ")" [function]
  rule hasUnsupported(.Objs) => false
  rule hasUnsupported(OTHER_UNIT , REST) => true
  rule hasUnsupported(Q , REST) => hasUnsupported(REST)
  rule hasUnsupported(ND , REST) => hasUnsupported(REST)
  rule hasUnsupported(NONE , REST) => hasUnsupported(REST)
  rule hasUnsupported(OTHER_PLAIN , REST) => hasUnsupported(REST)

  syntax Decision ::= "guard" "(" Objs ")" [function]
  rule guard(.Objs) => PROCEED
  rule guard(OTHER_UNIT , REST) => NOT_IMPLEMENTED
  rule guard(Q , REST) => guard(REST)
  rule guard(ND , REST) => guard(REST)
  rule guard(NONE , REST) => guard(REST)
  rule guard(OTHER_PLAIN , REST) => guard(REST)

  rule <k> quantityArrayUfunc(IS ; OS) => guard(concat(IS ; OS)) </k>
endmodule
