module MINI-PYTHON-DECONSTRUCT-SYNTAX
  syntax Class ::= Expression | F | OuterRef | Func | Value
                 | ExpressionList | ExpressionWrapper | When | Case
                 | OrderBy | Window | WindowFrame | RowRange | ValueRange
                 | RawSQL | Subquery | Exists
  syntax Args ::= args(String)
  syntax Kwargs ::= kwargs(String)
  syntax Path ::= rootPath(Class) [function]
                | modulePath(Class) [function]
                | noPath
  syntax Result ::= tuple(Path, Args, Kwargs) | noDeconstruct
  syntax Exp ::= deconstruct(Class, Class, Args, Kwargs)
               | deconstructMissing(Class, Args, Kwargs)
endmodule

module MINI-PYTHON-DECONSTRUCT
  imports MINI-PYTHON-DECONSTRUCT-SYNTAX
  imports BOOL

  configuration <k> $PGM:Exp </k>

  syntax Bool ::= hasRootPath(Class) [function]
  rule hasRootPath(Expression) => true
  rule hasRootPath(F) => true
  rule hasRootPath(OuterRef) => true
  rule hasRootPath(Func) => true
  rule hasRootPath(Value) => true
  rule hasRootPath(ExpressionList) => true
  rule hasRootPath(ExpressionWrapper) => true
  rule hasRootPath(When) => true
  rule hasRootPath(Case) => true
  rule hasRootPath(OrderBy) => true
  rule hasRootPath(Window) => true
  rule hasRootPath(WindowFrame) => true
  rule hasRootPath(RowRange) => true
  rule hasRootPath(ValueRange) => true
  rule hasRootPath(RawSQL) => false
  rule hasRootPath(Subquery) => false
  rule hasRootPath(Exists) => false

  rule <k> deconstruct(Klass, Klass, A, K) => tuple(rootPath(Klass), A, K) </k>
    requires hasRootPath(Klass)

  rule <k> deconstruct(Klass, ObjKlass, A, K) => tuple(modulePath(ObjKlass), A, K) </k>
    requires notBool (Klass ==K ObjKlass andBool hasRootPath(Klass))

  rule <k> deconstructMissing(_Klass, _A, _K) => noDeconstruct </k>
endmodule

