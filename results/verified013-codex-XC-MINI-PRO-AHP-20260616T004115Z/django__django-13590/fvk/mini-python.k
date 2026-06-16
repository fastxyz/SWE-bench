module MINI-PYTHON-LOOKUP-SYNTAX
  imports INT-SYNTAX
  imports STRING-SYNTAX

  syntax Values ::= ".Values"
                  | Value ";" Values [right]

  syntax Value ::= "atom(" Int ")"
                 | "expr(" Value ")"
                 | "list(" Values ")"
                 | "tuple(" Values ")"
                 | "ntuple(" String "," Values ")"

  syntax KResult ::= Value | Values
  syntax Value ::= "resolve(" Value ")" [function]
  syntax Values ::= "resolveAll(" Values ")" [function]
endmodule

module MINI-PYTHON-LOOKUP
  imports MINI-PYTHON-LOOKUP-SYNTAX

  configuration <k> $PGM:K </k>

  // Expression values abstract arbitrary resolve_expression() behavior.
  rule resolve(expr(V:Value)) => V

  // Container cases preserve observable container shape while resolving
  // members recursively and in order.
  rule resolve(list(VS:Values)) => list(resolveAll(VS))
  rule resolve(tuple(VS:Values)) => tuple(resolveAll(VS))
  rule resolve(ntuple(N:String, VS:Values)) => ntuple(N, resolveAll(VS))

  // Non-expression scalar values are unchanged.
  rule resolve(A:Value) => A [owise]

  rule resolveAll(.Values) => .Values
  rule resolveAll(V:Value ; VS:Values) => resolve(V) ; resolveAll(VS)
endmodule
