module MINI-ORM-QUERY-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax Alias ::= none | alias(Int)
  syntax Expr ::= selfQuery | ref(Alias) | lhsCol | extCol(Int, Bool)
  syntax Exprs ::= ".Exprs" [klabel(emptyExprs)]
                 | Expr ";" Exprs [right, klabel(exprCons)]
  syntax Exp ::= getGroupByCols(Alias, Exprs, Bool)

  syntax KResult ::= Alias | Expr | Exprs | Bool
endmodule

module MINI-ORM-QUERY
  imports MINI-ORM-QUERY-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:Exp </k>

  // Model of django.db.models.sql.query.Query.get_group_by_cols().
  // The Exprs argument is get_external_cols().
  // The Bool argument is any(col.possibly_multivalued for col in external_cols).
  rule <k> getGroupByCols(alias(A:Int), CS:Exprs, HAS_MULTI:Bool)
        => ref(alias(A)) ; .Exprs
       </k>

  rule <k> getGroupByCols(none, CS:Exprs, true)
        => selfQuery ; .Exprs
       </k>

  rule <k> getGroupByCols(none, CS:Exprs, false)
        => CS
       </k>
endmodule
