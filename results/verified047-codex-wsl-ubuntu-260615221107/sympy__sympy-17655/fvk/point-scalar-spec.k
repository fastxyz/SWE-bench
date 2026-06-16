// Constructed claims for sympy.geometry.point scalar-left multiplication.
// These claims were not machine-checked in this environment.

requires "mini-python-point.k"

module POINT-SCALAR-SPEC
  imports MINI-PYTHON-POINT

  // SPEC-PROVENANCE:
  // - from_prompt: "both lines give the same result" => left scalar
  //   multiplication must mirror right scalar multiplication.
  // - from_code: Point.__mul__ scales each coordinate and returns
  //   Point(coords, evaluate=False).
  claim <k> scalarValue(S) * point(Cs) => point(scale(Cs, S)) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "This line works fine" for point2 * sympify(2.0) =>
  //   preserve right multiplication.
  claim <k> point(Cs) * scalarValue(S) => point(scale(Cs, S)) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "both lines give the same result" => raw multiplication
  //   equivalence for the scalar/point pair.
  claim <k> scalarValue(S) * point(Cs) => point(Cs) * scalarValue(S) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: reported expression is point1 + sympify(2.0) * point2;
  //   the observable composed result must match point1 + point2 * scalar.
  claim <k> point(Ps) + (scalarValue(S) * point(Qs))
         => point(addCoords(Ps, scale(Qs, S))) </k>
    requires sameDim(Ps, Qs)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: adding Point._op_priority would make Expr.__add__ consider
  //   Point.__radd__; the shim must preserve the previous symbolic Add form.
  claim <k> scalarValue(S) + point(Cs) => symAdd(scalarValue(S), point(Cs)) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: adding Point._op_priority would make Expr.__sub__ consider
  //   Point.__rsub__; the shim must preserve Add(expr, -point).
  claim <k> scalarValue(S) - point(Cs)
         => symAdd(scalarValue(S), point(negCoords(Cs))) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: adding Point._op_priority would make Expr.__div__ consider
  //   Point.__rdiv__; the shim must preserve symbolic division by point.
  claim <k> scalarValue(S) / point(Cs) => symDiv(scalarValue(S), point(Cs)) </k>
    [all-path]
endmodule
