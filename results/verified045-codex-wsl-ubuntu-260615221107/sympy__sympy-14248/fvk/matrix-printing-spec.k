requires "mini-python.k"

module MATRIX-PRINTING-SPEC-SYNTAX
  imports MINI-PYTHON-SYNTAX
endmodule

module VERIFICATION
  imports MATRIX-PRINTING-SPEC-SYNTAX
  imports MINI-PYTHON
  imports BOOL

  syntax Pieces ::= expected(Terms, Bool) [function]
  syntax Bool ::= nonEmpty(Terms) [function]

  rule nonEmpty(.Terms) => false
  rule nonEmpty(T:Term ; TS:Terms) => true

  rule expected(.Terms, FIRST:Bool) => .Pieces
  rule expected(pos(B:Body) ; TS:Terms, true)
    => bare(B) ; expected(TS, false)
  rule expected(pos(B:Body) ; TS:Terms, false)
    => plus(B) ; expected(TS, false)
  rule expected(neg(B:Body) ; TS:Terms, true)
    => firstMinus(B) ; expected(TS, false)
  rule expected(neg(B:Body) ; TS:Terms, false)
    => minus(B) ; expected(TS, false)
endmodule

module MATRIX-PRINTING-SPEC
  imports VERIFICATION

  // SPEC-PROVENANCE:
  // - from_prompt: "differences like a-b ... are supposed to print like a-b"
  //   => negative matrix terms must contribute minus signs to the MatAdd join.
  // - from_prompt: "I tried three printers: str, pretty, and latex"
  //   => all three style entrypoints are in scope.
  // - from_code: each V1 method iterates expr.args and appends one signed term
  //   per iteration; this claim is the shared loop invariant for that shape.
  claim
    <k> loop(STYLE:Style, TS:Terms, FIRST:Bool, ACC:Pieces)
      => .K
    ... </k>
    <out> .Pieces => ACC ++ expected(TS, FIRST) </out>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: print(A - A*B - B) must not expose (-1) coefficients.
  // - from_code: StrPrinter._print_MatAdd uses the shared sign-classification
  //   loop and parenthesizes the positive body.
  claim
    <k> render(str, TS:Terms)
      => .K
    ... </k>
    <out> .Pieces => expected(TS, true) </out>
    requires nonEmpty(TS)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: latex(A - A*B - B) must not expose "-1 B" terms.
  // - from_code: LatexPrinter._print_MatAdd uses the shared sign-classification
  //   loop and style-specific body rendering.
  claim
    <k> render(latex, TS:Terms)
      => .K
    ... </k>
    <out> .Pieces => expected(TS, true) </out>
    requires nonEmpty(TS)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: pprint(A - A*B - B) must not render "+ -A*B".
  // - from_code: PrettyPrinter._print_MatAdd turns negative terms into
  //   negative-binding pretty forms, represented here by minus pieces.
  claim
    <k> render(pretty, TS:Terms)
      => .K
    ... </k>
    <out> .Pieces => expected(TS, true) </out>
    requires nonEmpty(TS)
    [all-path]
endmodule
