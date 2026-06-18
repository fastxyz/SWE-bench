requires "mini-python.k"

module POINT-SCALAR-MUL-SPEC
  imports MINI-PYTHON
  imports INT
  imports LIST
  imports BOOL

  // SPEC-PROVENANCE:
  // - from_prompt: "The expected behaviour is, that both lines give the same result"
  //   => SymPy scalar-left multiplication of a Point must scale coordinates just
  //      like Point scalar-right multiplication.
  // - from_prompt_hint: "You can multiply a Point on the right by a scalar but not on the left"
  //   => the repaired reflected multiplication route must call Point scaling.
  // - from_code: V1 gives Point priority 10001 over Expr priority 10000 and
  //   Point.__rmul__ delegates to Point.__mul__.
  claim
    <k> exprMul(scalar(F:Int), point(CS:List))
      => point(scale(CS, F)) ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt_hint: defining Point.__rmul__ should make left scalar
  //   multiplication use the same coordinate scaling as Point.__mul__.
  // - from_code: V1 Point.__rmul__(factor) returns self.__mul__(factor).
  claim
    <k> pointRMul(scalar(F:Int), point(CS:List))
      => point(scale(CS, F)) ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "point1 + point2 * sympy.sympify(2.0)" works and
  //   "point1 + sympy.sympify(2.0) * point2" should give the same result.
  // - from_default_domain: integer coordinates/scalars model exact scalar
  //   arithmetic; the proof shape is coordinate-wise and independent of
  //   concrete numeric values.
  claim
    <k> issueLeft(
          point(ListItem(X1:Int) ListItem(Y1:Int)),
          scalar(F:Int),
          point(ListItem(X2:Int) ListItem(Y2:Int)))
      => point(addCoords(
          ListItem(X1) ListItem(Y1),
          scale(ListItem(X2) ListItem(Y2), F))) ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: the right-multiplication expression is the known working
  //   comparator for the issue.
  claim
    <k> issueRight(
          point(ListItem(X1:Int) ListItem(Y1:Int)),
          scalar(F:Int),
          point(ListItem(X2:Int) ListItem(Y2:Int)))
      => point(addCoords(
          ListItem(X1) ListItem(Y1),
          scale(ListItem(X2) ListItem(Y2), F))) ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_test: direct Point.__radd__(Point) is expected to preserve
  //   existing point addition behavior.
  // - from_code: V1 only constructs symbolic Add for Expr-left operands; non-Expr
  //   operands still delegate to the left operand's __add__ method.
  claim
    <k> exprAdd(scalar(F:Int), point(CS:List))
      => symAdd(scalar(F), point(CS)) ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_test: direct Point.__rsub__(Point) is expected to preserve
  //   existing point subtraction behavior.
  // - from_code: V1 mirrors Expr.__sub__ for Expr-left subtraction by producing
  //   Add(other, -self).
  claim
    <k> exprSub(scalar(F:Int), point(CS:List))
      => symAdd(scalar(F), point(negCoords(CS))) ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: adding _op_priority would otherwise route Expr-left division
  //   through GeometryEntity.__rdiv__; V1 preserves Expr symbolic division shape.
  // - from_compatibility_audit: division is not part of the issue intent but is
  //   a touched reflected operator and must not recurse.
  claim
    <k> exprDiv(scalar(F:Int), point(CS:List))
      => symMul(scalar(F), symPow(point(CS), scalar(0 -Int 1))) ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_compatibility_audit: Point's priority is 10001, below matrix/vector
  //   style priorities observed in public source, so those richer left operands
  //   keep their own multiplication semantics.
  claim
    <k> exprMul(foreign(10010), point(CS:List))
      => foreignMul(foreign(10010), point(CS)) ... </k>
    [all-path]
endmodule
