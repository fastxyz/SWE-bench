module MINI-DOCFIELDS-SYNTAX
  imports STRING
  imports BOOL

  syntax FieldArg ::= single(String)
                    | commaList(String, String)
                    | inlineTyped(String, String)

  syntax TypeMap ::= ".TypeMap"
                   | type(String, String, TypeMap)

  syntax Result ::= result(String, TypeMap)
                  | rendered(String, String)
  syntax Result ::= transformParam(Bool, FieldArg, TypeMap) [function]
                  | attachExplicitType(FieldArg, String, Result) [function]
                  | renderField(Result) [function]

  syntax String ::= render(FieldArg) [function]

  rule render(single(N)) => N
  rule render(commaList(A, B)) => A +String ", " +String B
  rule render(inlineTyped(_, N)) => N
endmodule

module MINI-DOCFIELDS
  imports MINI-DOCFIELDS-SYNTAX

  configuration <k> $PGM:K </k>

  // Non-typed fields keep their field argument.
  rule transformParam(false, F, M) => result(render(F), M)

  // Typed fields with no whitespace split keep their field argument.
  rule transformParam(true, single(N), M) => result(N, M)

  // V2 rule: "x1, x2" is a comma-separated field argument, not
  // the inline ":param type name:" shorthand.
  rule transformParam(true, commaList(A, B), M)
        => result(A +String ", " +String B, M)

  // Documented shorthand: ":param str sender:" supplies an inline type.
  rule transformParam(true, inlineTyped(T, N), M)
        => result(N, type(N, T, M))

  // Explicit type fields are keyed by the exact field argument text.
  rule attachExplicitType(F, T, result(N, M))
        => result(N, type(render(F), T, M))

  // Rendering attaches a type only when the transformed parameter name and
  // explicit type key are equal.
  rule renderField(result(N, type(N, T, M))) => rendered(N, T)
endmodule
