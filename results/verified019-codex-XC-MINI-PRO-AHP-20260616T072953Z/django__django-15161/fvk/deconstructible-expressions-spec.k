requires "mini-python-deconstruct.k"

module DECONSTRUCTIBLE-EXPRESSIONS-SPEC
  imports MINI-PYTHON-DECONSTRUCT

  // SPEC-PROVENANCE:
  // - from_prompt: "F() ... changed it to deconstruct to django.db.models.F()"
  // - from_prompt: "same technique can be applied to other expressions"
  // - from_code: django.db.models exports these classes directly.
  claim <k> deconstruct(Expression, Expression, args("A"), kwargs("K"))
        => tuple(rootPath(Expression), args("A"), kwargs("K")) </k> [all-path]
  claim <k> deconstruct(F, F, args("A"), kwargs("K"))
        => tuple(rootPath(F), args("A"), kwargs("K")) </k> [all-path]
  claim <k> deconstruct(OuterRef, OuterRef, args("A"), kwargs("K"))
        => tuple(rootPath(OuterRef), args("A"), kwargs("K")) </k> [all-path]
  claim <k> deconstruct(Func, Func, args("A"), kwargs("K"))
        => tuple(rootPath(Func), args("A"), kwargs("K")) </k> [all-path]
  claim <k> deconstruct(Value, Value, args("A"), kwargs("K"))
        => tuple(rootPath(Value), args("A"), kwargs("K")) </k> [all-path]
  claim <k> deconstruct(ExpressionList, ExpressionList, args("A"), kwargs("K"))
        => tuple(rootPath(ExpressionList), args("A"), kwargs("K")) </k> [all-path]
  claim <k> deconstruct(ExpressionWrapper, ExpressionWrapper, args("A"), kwargs("K"))
        => tuple(rootPath(ExpressionWrapper), args("A"), kwargs("K")) </k> [all-path]
  claim <k> deconstruct(When, When, args("A"), kwargs("K"))
        => tuple(rootPath(When), args("A"), kwargs("K")) </k> [all-path]
  claim <k> deconstruct(Case, Case, args("A"), kwargs("K"))
        => tuple(rootPath(Case), args("A"), kwargs("K")) </k> [all-path]
  claim <k> deconstruct(OrderBy, OrderBy, args("A"), kwargs("K"))
        => tuple(rootPath(OrderBy), args("A"), kwargs("K")) </k> [all-path]
  claim <k> deconstruct(Window, Window, args("A"), kwargs("K"))
        => tuple(rootPath(Window), args("A"), kwargs("K")) </k> [all-path]
  claim <k> deconstruct(WindowFrame, WindowFrame, args("A"), kwargs("K"))
        => tuple(rootPath(WindowFrame), args("A"), kwargs("K")) </k> [all-path]
  claim <k> deconstruct(RowRange, RowRange, args("A"), kwargs("K"))
        => tuple(rootPath(RowRange), args("A"), kwargs("K")) </k> [all-path]
  claim <k> deconstruct(ValueRange, ValueRange, args("A"), kwargs("K"))
        => tuple(rootPath(ValueRange), args("A"), kwargs("K")) </k> [all-path]

  // SPEC-PROVENANCE:
  // - from_code: deconstructible uses the custom path only when type(obj) is klass.
  // - obligation: inherited/internal helpers keep fallback module paths.
  claim <k> deconstruct(Expression, RawSQL, args("A"), kwargs("K"))
        => tuple(modulePath(RawSQL), args("A"), kwargs("K")) </k> [all-path]

  // SPEC-PROVENANCE:
  // - from_code: Subquery and Exists do not have deconstruct in V1.
  // - obligation: no new deconstruct contract is introduced by path-shortening.
  claim <k> deconstructMissing(Subquery, args("A"), kwargs("K"))
        => noDeconstruct </k> [all-path]
  claim <k> deconstructMissing(Exists, args("A"), kwargs("K"))
        => noDeconstruct </k> [all-path]
endmodule

