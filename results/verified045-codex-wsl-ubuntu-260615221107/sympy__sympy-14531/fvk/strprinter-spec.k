// Constructed, not machine-checked.
// Exact commands to check later:
//   kompile fvk/mini-python-printing.k --backend haskell
//   kast --backend haskell fvk/strprinter-spec.k
//   kprove fvk/strprinter-spec.k

requires "mini-python-printing.k"

module STRPRINTER-SPEC
    imports MINI-PYTHON-PRINTING

    // SPEC-PROVENANCE:
    // - from_prompt: "sstr(Eq(x, S(1)/2), sympy_integers=True)" must produce
    //   "Eq(x, S(1)/2)".
    // - from_code: StrPrinter._print_Relational formats equality-like
    //   relationals.
    claim
      <k> printStr(true, RelExpr("==", Sym("x"), Rat(1, 2)))
       => "Eq(x, S(1)/2)" </k>

    // SPEC-PROVENANCE:
    // - from_prompt: "sstr(Limit(x, x, S(1)/2), sympy_integers=True)" must
    //   produce "Limit(x, x, S(1)/2)".
    // - from_code: StrPrinter._print_Limit has the default-dir branch.
    claim
      <k> printStr(true, LimitExpr(Sym("x"), Sym("x"), Rat(1, 2), "+"))
       => "Limit(x, x, S(1)/2)" </k>

    // SPEC-PROVENANCE:
    // - from_prompt: "python(Eq(x, y))" must declare both x and y before
    //   emitting the Eq expression.
    // - from_code: PythonPrinter collects declarations by visiting symbols.
    claim
      <k> pythonProgram(RelExpr("==", Sym("x"), Sym("y")))
       => "x = Symbol('x')\ny = Symbol('y')\ne = Eq(x, y)" </k>

    // SPEC-PROVENANCE:
    // - from_prompt: printer settings are not respected by certain
    //   subexpressions; examples are members of the same recursive-printing
    //   family.
    // - from_docs: the printer subsystem says nested expressions must use
    //   self._print rather than str() to work correctly.
    // - from_findings: V1 left these direct subexpression interpolations in
    //   StrPrinter.
    claim
      <k> printStr(true, AppliedPredicate(Pred("integer"), Rat(1, 2)))
       => "Q.integer(S(1)/2)" </k>

    claim
      <k> printStr(true, ExprCondPair(Rat(1, 2), RelExpr("==", Sym("x"), Rat(1, 2))))
       => "(S(1)/2, Eq(x, S(1)/2))" </k>

    claim
      <k> printStr(true, IntervalExpr(Rat(1, 2), IntExpr(1), ""))
       => "Interval(S(1)/2, S(1))" </k>

    claim
      <k> printStr(true, Lambda1(Sym("x"), Rat(1, 2)))
       => "Lambda(x, S(1)/2)" </k>

    claim
      <k> printStr(true, MatrixElementExpr(Sym("A"), IntExpr(0), IntExpr(1)))
       => "A[S(0), S(1)]" </k>

    claim
      <k> printStr(true, NormalExpr(Rat(1, 2), IntExpr(1)))
       => "Normal(S(1)/2, S(1))" </k>

    claim
      <k> printStr(true, UniformExpr(Rat(1, 2), IntExpr(1)))
       => "Uniform(S(1)/2, S(1))" </k>
endmodule
