module MINI-DJANGO-AGGREGATE-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX

  syntax AggClass ::= "Avg" | "Sum" | "Count" | "Max" | "Min" | "Other"
  syntax Exp ::= init(AggClass, Bool)
               | asSql(String, Bool, String)
  syntax Result ::= Obj(Bool)
                  | TypeError(String)
                  | Sql(String)
endmodule

module MINI-DJANGO-AGGREGATE
  imports MINI-DJANGO-AGGREGATE-SYNTAX
  imports BOOL
  imports STRING

  configuration <k> $PGM:Exp </k>

  syntax Bool ::= allowDistinct(AggClass) [function]
  rule allowDistinct(Avg) => true
  rule allowDistinct(Sum) => true
  rule allowDistinct(Count) => true
  rule allowDistinct(Max) => false
  rule allowDistinct(Min) => false
  rule allowDistinct(Other) => false

  rule <k> init(C, true) => TypeError("does not allow distinct") </k>
    requires allowDistinct(C) ==Bool false
  rule <k> init(C, D) => Obj(D) </k>
    requires D ==Bool false orBool allowDistinct(C) ==Bool true

  rule <k> asSql(FN, true, EXPR) => Sql(FN +String "(DISTINCT " +String EXPR +String ")") </k>
  rule <k> asSql(FN, false, EXPR) => Sql(FN +String "(" +String EXPR +String ")") </k>
endmodule
