module MINI-DJANGO-EXPRESSIONS-SYNTAX
  syntax Alias ::= NoAlias | Alias(String)
  syntax Cols ::= NoCols | SelfCol(String) | ChildCols(String) | AliasRef(String)
  syntax Expr ::= Value(Int)
                | AliasAware(String, Cols)
                | LegacyNoAlias(String, Cols)
                | Wrapper(Expr)
  syntax Result ::= Ok(Cols) | Warn(String, Cols) | TypeError
endmodule

module MINI-DJANGO-EXPRESSIONS
  imports MINI-DJANGO-EXPRESSIONS-SYNTAX
  imports INT
  imports STRING
  imports BOOL

  configuration <k> $PGM:K </k>

  syntax Bool ::= acceptsAlias(Expr) [function]
  rule acceptsAlias(Value(_)) => true
  rule acceptsAlias(AliasAware(_, _)) => true
  rule acceptsAlias(LegacyNoAlias(_, _)) => false
  rule acceptsAlias(Wrapper(E)) => true

  syntax Result ::= childGroupBy(Expr, Alias) [function]
  rule childGroupBy(Value(_), _) => Ok(NoCols)
  rule childGroupBy(AliasAware(_, Cs), NoAlias) => Ok(Cs)
  rule childGroupBy(AliasAware(_, _), Alias(A)) => Ok(AliasRef(A))
  rule childGroupBy(LegacyNoAlias(_, _), _) => TypeError

  syntax Result ::= childGroupByNoAlias(Expr) [function]
  rule childGroupByNoAlias(Value(_)) => Ok(NoCols)
  rule childGroupByNoAlias(AliasAware(_, Cs)) => Ok(Cs)
  rule childGroupByNoAlias(LegacyNoAlias(_, Cs)) => Ok(Cs)

  syntax Result ::= wrapperGroupBy(Expr, Alias) [function]
  rule wrapperGroupBy(Wrapper(E), A) => childGroupBy(E, A)
    requires acceptsAlias(E) ==Bool true
  rule wrapperGroupBy(Wrapper(LegacyNoAlias(Name, Cs)), _) => Warn(Name, Cs)
endmodule
