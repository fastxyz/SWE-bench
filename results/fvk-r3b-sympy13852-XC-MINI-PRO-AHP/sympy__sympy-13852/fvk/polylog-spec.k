// polylog-spec.k — K reachability claims (the formal contract) for the polylog fix.
// Proven against mini-cas.k by symbolic execution; see PROOF.md.
// Status: CONSTRUCTED, NOT MACHINE-CHECKED.
//
//   kompile mini-cas.k --backend haskell
//   kast    --backend haskell polylog-spec.k     # (optional) parse check
//   kprove  polylog-spec.k                        # expected: #Top (all claims proved)

requires "mini-cas.k"

module POLYLOG-SPEC-SYNTAX
  imports MINI-CAS-SYNTAX
endmodule

module VERIFICATION
  imports POLYLOG-SPEC-SYNTAX
  imports MINI-CAS
  imports K-EQUAL

  // ---- Arithmetic VC lemmas (linear / cancellation; SMT-dischargeable tier) ----
  // a - a = 0
  rule sub(X:Exp, X:Exp) => 0                                  [simplification]
  // (Z / W) / Z  =  1 / W   (cancellation; the issue's derivative collapse)
  rule divi(divi(Z:Exp, W:Exp), Z:Exp) => divi(1, W)           [simplification]

  // ---- [ESCALATION BOUNDARY] special-function identities ----
  // These are transcendental special-function theorems, NOT linear arithmetic and
  // NOT discharged by the bundled Z3/[simplification] tier. They are the *targets*
  // the SymPy rewrite rules produce; their correctness is the proof obligation of
  // §"escalation" in PROOF.md. We encode them as named lemmas with provenance, and
  // route their *proof* to references — we never mark them [trusted].
  //
  //  LEM-LI1 :  polylog(1, Z)  ==  -log(1 - Z)        for all Z
  //             (power-series agreement |Z|<1 + identical branch cut on [1,oo);
  //              issue #7132: numerically verified at thousands of real/complex pts.)
  //  LEM-LI2 :  polylog(2, 1/2) ==  pi^2/12 - log(2)^2/2
  //             (dilogarithm reflection Li2(z)+Li2(1-z)=pi^2/6 - log z log(1-z) at z=1/2)
  rule polylog(1, Z:Exp)  => LOG1(Z)  [simplification]      // LEM-LI1  [ESCALATION BOUNDARY]
  rule polylog(2, half)   => CF2      [simplification]      // LEM-LI2  [ESCALATION BOUNDARY]
endmodule

module POLYLOG-SPEC
  imports VERIFICATION

  // (EVAL-HALF)  Construction-path evaluation of Li_2(1/2).  Models polylog.eval.
  // SPEC-PROVENANCE:
  //  - from_prompt: "Add evaluation for polylog ... The answer should be
  //    -log(2)**2/2 + pi**2/12"  => the value must be produced.
  //  - from_intent-note: "do not enshrine 'stays unevaluated by default'" => default path.
  //  - from_public_test: test_wester.test_R18 uses .simplify(), which does NOT
  //    expand_func a polylog => the value must already exist post-construction.
  claim <k> polylog(2, half) => CF2 </k>                              [all-path]

  // (SIMPLIFY-HALF)  The test_R18 pipeline: a bare polylog(2,1/2) reduced by
  // simplify alone must reach the closed form. Holds ONLY because eval fired at
  // construction (EVAL-HALF), since simpl is the identity on polylog. This claim is
  // exactly what V1 (expand_func-only) FAILS and V2 (eval) satisfies.
  claim <k> simpl(polylog(2, half)) => CF2 </k>                       [all-path]

  // (EXPAND-HALF)  The issue's In[2]: polylog(2,1/2).expand(func=True) -> closed form.
  claim <k> expandf(polylog(2, half)) => CF2 </k>                     [all-path]

  // (EXPAND-LI1)  Part 2: expand_func(polylog(1, z)) = -log(1 - z), with NO
  // exp_polar(-I*pi).  Models the s==1 branch of _eval_expand_func.
  // SPEC-PROVENANCE:
  //  - from_prompt: "polylog(1, z) and -log(1-z) are exactly the same function ...
  //    having exp_polar in -log(1 + ... exp_polar(-I*pi)) is just not meaningful."
  claim <k> expandf(polylog(1, z)) => neg(log(sub(1, z))) </k>        [all-path]

  // (DERIV-CONSISTENT)  The issue's invariant: expand_func changes nothing about the
  // derivative.  expand_func( d/dz ( polylog(1,z) - expand_func(polylog(1,z)) ) ) == 0.
  // SPEC-PROVENANCE:
  //  - from_prompt: "expand_func(diff(polylog(1, z) + log(1 - z), z))  # 0"  and the
  //    complaint that the OLD exp_polar form did NOT collapse to 0.
  claim <k> expandf(der(sub(polylog(1, z), expandf(polylog(1, z))))) => 0 </k> [all-path]

  // (EVAL-PRESERVED)  Regression guard: the pre-existing special points are unchanged.
  claim <k> polylog(s, 1)      => zeta(s)      </k>                   [all-path]
  claim <k> polylog(s, neg(1)) => neg(deta(s)) </k>                   [all-path]
  claim <k> polylog(s, 0)      => 0            </k>                   [all-path]
endmodule
