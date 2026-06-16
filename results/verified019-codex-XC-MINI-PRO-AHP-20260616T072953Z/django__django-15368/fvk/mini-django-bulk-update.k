module MINI-DJANGO-BULK-UPDATE-SYNTAX
  imports STRING-SYNTAX

  // Minimal value taxonomy for the audited bulk_update() branch.
  // Plain(V) represents a field value without resolve_expression().
  // Resolvable(E) represents any object with resolve_expression(), including F().
  syntax Attr ::= "Plain" "(" String ")"
                | "Resolvable" "(" Expr ")"

  syntax Expr ::= "FRef" "(" String ")"       // Django F("field")
                | "ExprNode" "(" String ")"   // other expression-like node
                | "Value" "(" String ")"      // Django Value(...)
                | "Column" "(" String ")"     // resolved same-row column reference
                | "Param" "(" String ")"      // SQL parameter literal

  syntax Cmd ::= "bulkThen" "(" Attr ")"
               | "normalize" "(" Attr ")"
               | "resolveForUpdate" "(" Expr ")"

  syntax KItem ::= "#resolveForUpdate"
  syntax KResult ::= Expr
endmodule

module MINI-DJANGO-BULK-UPDATE
  imports MINI-DJANGO-BULK-UPDATE-SYNTAX

  configuration <k> $PGM:Cmd </k>

  // V1 behavior from QuerySet.bulk_update():
  // if not hasattr(attr, "resolve_expression"): attr = Value(attr, output_field=field)
  rule <k> bulkThen(A:Attr) => normalize(A) ~> #resolveForUpdate ... </k>
  rule <k> normalize(Plain(V:String)) => Value(V) ... </k>
  rule <k> normalize(Resolvable(E:Expr)) => E ... </k>

  // Downstream update resolution, modeled from When.resolve_expression(),
  // Case.resolve_expression(), and UpdateQuery.add_update_fields().
  rule <k> E:Expr ~> #resolveForUpdate => resolveForUpdate(E) ... </k>
  rule <k> resolveForUpdate(Value(V:String)) => Param(V) ... </k>
  rule <k> resolveForUpdate(FRef(Name:String)) => Column(Name) ... </k>
  rule <k> resolveForUpdate(ExprNode(SQL:String)) => ExprNode(SQL) ... </k>
endmodule
