module MINI-DJANGO-ORDERING-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX

  syntax Dir ::= "asc" | "desc"
  syntax Context ::= "ctx" "(" String "," String ")"
  syntax Path ::= String
  syntax Expr ::= "f" "(" Path ")"
                | "value" "(" String ")"
                | "lower" "(" Expr ")"
                | "orderby" "(" Expr "," Dir ")"
                | "node" "(" Exprs ")"
                | "foreignNode"
                | "col" "(" String "," String ")"
  syntax Exprs ::= ".Exprs" | Expr "," Exprs
  syntax Item ::= "strItem" "(" String ")" | "exprItem" "(" Expr ")"
  syntax Result ::= "ordering" "(" Expr "," "false" ")"
                  | "stringPathResult"
                  | "stringTypeError"

  syntax KResult ::= Dir | Context | Expr | Exprs | Item | Result
endmodule

module MINI-DJANGO-ORDERING
  imports MINI-DJANGO-ORDERING-SYNTAX

  configuration <k> $PGM:K </k>

  syntax Expr ::= "resolveExpr" "(" Expr "," Context ")"
  syntax Exprs ::= "resolveExprs" "(" Exprs "," Context ")"
  syntax Expr ::= "makeOrder" "(" Expr "," Dir ")"
  syntax Dir ::= "reverse" "(" Dir ")"
  syntax String ::= "setupJoin" "(" Path "," Context ")" [function]

  rule <k> reverse(asc) => desc ... </k>
  rule <k> reverse(desc) => asc ... </k>

  rule <k> resolveExpr(f(P), C) => col(P, setupJoin(P, C)) ... </k>
  rule <k> resolveExpr(value(V), C) => value(V) ... </k>
  rule <k> resolveExpr(lower(E), C) => lower(resolveExpr(E, C)) ... </k>
  rule <k> resolveExpr(orderby(E, D), C) => orderby(resolveExpr(E, C), D) ... </k>
  rule <k> resolveExpr(node(ES), C) => node(resolveExprs(ES, C)) ... </k>
  rule <k> resolveExpr(foreignNode, C) => foreignNode ... </k>

  rule <k> resolveExprs(.Exprs, C) => .Exprs ... </k>
  rule <k> resolveExprs((E:Expr, ES:Exprs), C:Context)
        => (resolveExpr(E, C), resolveExprs(ES, C)) ... </k>

  rule <k> makeOrder(orderby(E, D), asc) => orderby(E, D) ... </k>
  rule <k> makeOrder(orderby(E, D), desc) => orderby(E, reverse(D)) ... </k>
  rule <k> makeOrder(E, asc) => orderby(E, asc) ... </k> requires notBool isOrderBy(E)
  rule <k> makeOrder(E, desc) => orderby(E, desc) ... </k> requires notBool isOrderBy(E)

  syntax Bool ::= "isOrderBy" "(" Expr ")" [function]
  rule isOrderBy(orderby(_, _)) => true
  rule isOrderBy(f(_)) => false
  rule isOrderBy(value(_)) => false
  rule isOrderBy(lower(_)) => false
  rule isOrderBy(node(_)) => false
  rule isOrderBy(foreignNode) => false
  rule isOrderBy(col(_, _)) => false

  syntax Result ::= "findOrderingName" "(" Item "," Context "," Dir ")"
  rule <k> findOrderingName(exprItem(E), C, D) => ordering(makeOrder(resolveExpr(E, C), D), false) ... </k>
  rule <k> findOrderingName(strItem(_), _, _) => stringPathResult ... </k>

  syntax Result ::= "legacyGetOrderDir" "(" Item ")"
  rule <k> legacyGetOrderDir(exprItem(_)) => stringTypeError ... </k>
endmodule
