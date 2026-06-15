// polylog-expand-spec.k  —  CONSTRUCTED, NOT MACHINE-CHECKED
//
// K reachability claims for polylog._eval_expand_func (the V2 fix) over the
// mini-sympy.k semantics.  Each claim carries SPEC-PROVENANCE tracing it to the
// public issue (benchmark/PROBLEM.md) or the SymPy docstring / public test.
//
// Machine-check later with:
//   kompile mini-sympy.k --backend haskell
//   kast    --backend haskell polylog-expand-spec.k     # (optional) parse check
//   kprove  polylog-expand-spec.k                       # expect: #Top

requires "mini-sympy.k"

module POLYLOG-EXPAND-SPEC-SYNTAX
  imports MINI-SYMPY-SYNTAX
endmodule

module VERIFICATION
  imports POLYLOG-EXPAND-SPEC-SYNTAX
  imports MINI-SYMPY
  imports K-EQUAL
endmodule

module POLYLOG-EXPAND-SPEC
  imports VERIFICATION

  // -------------------------------------------------------------------
  // (PL1)  s == 1 expands to -log(1 - z), with NO exp_polar factor.
  // SPEC-PROVENANCE:
  // - from_prompt: "polylog(1, z) and -log(1-z) are exactly the same function
  //                 for all purposes." => expand_func(polylog(1,z)) = -log(1-z)
  // - from_prompt: "I don't see a reason for exp_polar here" => the result must
  //                not contain exp_polar(-I*pi).
  // - from_docs: docstring ">>> expand_func(polylog(1, z))  -log(-z + 1)"
  // - from_code: branch `if s == 1: return -log(1 - z)`
  claim <k> expandPolylog(1, z) => Neg(Log(Sub(1, z))) </k>  [all-path]

  // -------------------------------------------------------------------
  // (PL2)  s == 2, z == 1/2 expands to the dilogarithm value.
  // SPEC-PROVENANCE:
  // - from_prompt: "polylog(2, Rational(1,2)).expand(func=True)" ... "The answer
  //                 should be -log(2)**2/2 + pi**2/12" => the required value.
  // - from_docs: docstring ">>> expand_func(polylog(2, Rational(1, 2)))
  //                          -log(2)**2/2 + pi**2/12"
  // - from_code: branch `if s == 2 and z == S.Half: return -log(2)**2/2 + pi**2/12`
  // NOTE: NOT marked "stays unevaluated by default" — per FVK intent-evidence.md
  //       the unevaluated In[1] display is the *symptom*, not an invariant.
  claim <k> expandPolylog(2, Half)
         => Add(Neg(Div(Pow(Log(2), 2), 2)), Div(Pow(Pi, 2), 12)) </k>  [all-path]

  // -------------------------------------------------------------------
  // (PL0)  s == 0 expands to z/(1 - z)  (s<=0 branch, UNCHANGED by the fix).
  // SPEC-PROVENANCE:
  // - from_public_test: test_polylog_expansion "myexpand(polylog(0, z), z/(1 - z))"
  // - from_code: s<=0 branch, loop run 0 times.
  claim <k> expandPolylog(0, z) => Div(z, Sub(1, z)) </k>  [all-path]

  // -------------------------------------------------------------------
  // (PLF)  Fallback: a polylog the method cannot reduce is returned unchanged.
  // SPEC-PROVENANCE:
  // - from_public_test: "myexpand(polylog(-5, z), None)" expects it still expands
  //                      via the s<=0 loop, and symbolic-s polylogs are returned
  //                      verbatim (used throughout test_lerchphi_expansion).
  // - from_code: final `return polylog(s, z)`.
  // Representative: integer s == 3 has no closed form -> PolyLog(3, z).
  claim <k> expandPolylog(3, z) => PolyLog(3, z) </k>  [all-path]

  // Representative: s == 2 but z != 1/2 must NOT hit the dilog branch.
  claim <k> expandPolylog(2, z) => PolyLog(2, z) </k>  [all-path]

  // -------------------------------------------------------------------
  // (PLDERIV-FIX)  THE BUG-FIX PROPERTY.  The derivative of the *expansion* of
  // polylog(1, z) equals 1/(1-z), which is exactly  d/dz polylog(1, z)  after
  // expanding polylog(0, z).  This is the identity the issue says the OLD code
  // violated ("expand_func changes the derivative of the function").
  // SPEC-PROVENANCE:
  // - from_prompt: "expand_func(diff(polylog(1, z) - expand_func(polylog(1, z)),
  //                 z))" must be 0  =>  d/dz(expansion) == d/dz(polylog(1,z)).
  // - from_prompt: SymPy "agree they have the same derivative, which is z/(1-z)"
  //                [i.e. polylog(0,z) = z/(1-z), so d/dz polylog(1,z)=1/(1-z)].
  claim <k> Diff(Neg(Log(Sub(1, z))), z) => Div(1, Sub(1, z)) </k>  [all-path]

  // The right-hand reference: d/dz polylog(1,z) = polylog(0,z)/z, and
  // expandPolylog(0,z)/z = (z/(1-z))/z = 1/(1-z).  Same normal form as above,
  // so V2's expansion is derivative-consistent (the OLD exp_polar form was not).
  claim <k> Div(expandPolylog(0, z), z) => Div(1, Sub(1, z)) </k>  [all-path]
endmodule
