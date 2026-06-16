requires "mini-python-printer.k"

module MPMATH-RATIONAL-PRINTER-SPEC
  imports MINI-PYTHON-PRINTER
  imports INT
  imports BOOL

  // SPEC-PROVENANCE:
  // - from_prompt: "lambdify(modules='mpmath') doesn't wrap rationals"
  //   => non-integer rational output must be mpmath-wrapped.
  // - from_prompt: "232/3 isn't evaluated at full precision"
  //   => output must not be bare Python integer division.
  // - from_code: V1 `_print_Rational` returns F(p)/F(q) for p >= 0.
  claim
    <k> printRational(bareMpf, rat(P:Int, D:Int))
      => div(mpfCall(bareMpf, P), mpfCall(bareMpf, D)) </k>
    requires D >Int 1 andBool P >=Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: obligation covers all non-integer rationals, not only the
  //   positive reproducer constant.
  // - from_code: V1 prints a leading sign and wraps abs(p), q.
  claim
    <k> printRational(bareMpf, rat(P:Int, D:Int))
      => neg(div(mpfCall(bareMpf, 0 -Int P), mpfCall(bareMpf, D))) </k>
    requires D >Int 1 andBool P <Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: the precision bug is rational division; q == 1 has no
  //   division to wrap.
  // - from_code: V1 preserves integer output for q == 1.
  claim
    <k> printRational(bareMpf, rat(P:Int, 1)) => intLit(P) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: `_module_format('mpmath.mpf')` can also produce a fully
  //   qualified name outside lambdify's fully_qualified_modules=False mode.
  // - frame condition: the same rational wrapping shape holds in that mode.
  claim
    <k> printRational(fullMpmathMpf, rat(P:Int, D:Int))
      => div(mpfCall(fullMpmathMpf, P), mpfCall(fullMpmathMpf, D)) </k>
    requires D >Int 1 andBool P >=Int 0
    [all-path]
endmodule
