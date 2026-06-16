module MINI-PYCODE-UNPARSE-SYNTAX
  imports INT-SYNTAX
  imports STRING-SYNTAX

  syntax Expr ::= IntLit(Int)
                | Atom(String)
                | Tuple(Exprs)
                | Subscript(Expr, Expr)

  syntax Exprs ::= ".Exprs"
                 | Expr
                 | Expr "," Exprs [right]

  syntax String ::= render(Expr) [function]
                  | joinTuple(Exprs) [function]
endmodule

module MINI-PYCODE-UNPARSE
  imports MINI-PYCODE-UNPARSE-SYNTAX
  imports INT
  imports STRING

  configuration <k> $PGM:K </k>

  // Minimal semantics for the observable under audit: rendered strings.
  rule render(IntLit(I:Int)) => Int2String(I)
  rule render(Atom(S:String)) => S

  rule render(Tuple(.Exprs)) => "()"
  rule render(Tuple(E:Expr)) => "(" +String render(E) +String ",)"
  rule render(Tuple(E:Expr , ES:Exprs))
    => "(" +String render(E) +String ", " +String joinTuple(ES) +String ")"

  rule joinTuple(E:Expr) => render(E)
  rule joinTuple(E:Expr , ES:Exprs) => render(E) +String ", " +String joinTuple(ES)

  // Subscript tuple slices omit tuple parentheses but must keep the comma that
  // distinguishes a one-element tuple key from a scalar key.
  rule render(Subscript(V:Expr, Tuple(E:Expr)))
    => render(V) +String "[" +String render(E) +String ",]"
  rule render(Subscript(V:Expr, Tuple(E:Expr , ES:Exprs)))
    => render(V) +String "[" +String render(E) +String ", "
       +String joinTuple(ES) +String "]"
  rule render(Subscript(V:Expr, S:Expr))
    => render(V) +String "[" +String render(S) +String "]" [owise]
endmodule
