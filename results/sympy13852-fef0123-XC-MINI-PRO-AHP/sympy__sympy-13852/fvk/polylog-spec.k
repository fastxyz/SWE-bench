// polylog-spec.k  --  K reachability claims for the polylog fix.
// CONSTRUCTED, NOT MACHINE-CHECKED.  Discharge with:
//
//   kompile mini-sympy.k --backend haskell
//   kast    --backend haskell polylog-spec.k   # optional: confirm parse
//   kprove  polylog-spec.k                      # expected: #Top (all claims proved)
//
// Each claim is a reachability rule  phi_pre => phi_post  over MINI-SYMPY.
// Logical/closed-form constant used below:
//   DILOG_HALF  ==  pi ^ 2 / 12  -  log(2) ^ 2 / 2     (== Li_2(1/2))

module POLYLOG-SPEC
  imports MINI-SYMPY

  // ==========================================================================
  // (EVAL-DILOG)  Construction-path value of the dilogarithm at 1/2.
  //   The bare object collapses to the closed form with NO opt-in transform.
  // SPEC-PROVENANCE:
  //   from_prompt: "The answer should be -log(2)**2/2 + pi**2/12"
  //   from_default_domain: a value at a specific/concrete argument is an intrinsic
  //                        constant -> binds on the construction path (eval).
  //   from_code: polylog.eval now returns it for s==2, z==S.Half.
  // ==========================================================================
  claim <k> polylog(2, half) => pi ^ 2 / 12 - log(2) ^ 2 / 2 </k>      [all-path]

  // ==========================================================================
  // (SIMPLIFY-R18)  The test_wester.test_R18 path:  Sum(1/(2^k k^2)).doit().simplify().
  //   doit -> polylog(2,1/2) -> (eval) DILOG_HALF; simplify is then the identity.
  //   This is the claim that DISTINGUISHES V2 from V1: simplify has no expand_func
  //   step, so it can only succeed because eval already collapsed the polylog.
  // SPEC-PROVENANCE:
  //   from_public_test: test_R18  "assert T.simplify() == -log(2)**2/2 + pi**2/12"
  //                     ( @XFAIL, linked to issue #7132 -- the fix is meant to land it )
  //   from_code: simplify() never calls expand_func (simplify.py:556-620).
  // ==========================================================================
  claim <k> simplify(Li2sum_half) => pi ^ 2 / 12 - log(2) ^ 2 / 2 </k> [all-path]

  // ==========================================================================
  // (EXPAND-DILOG)  The issue's own surface: polylog(2, 1/2).expand(func=True).
  //   Still yields the closed form under V2 -- because construction already
  //   reduced the polylog and expand_func is the identity on the result.
  //   (Guarantees the fix does not regress the workaround the issue used.)
  // ==========================================================================
  claim <k> expand(polylog(2, half)) => pi ^ 2 / 12 - log(2) ^ 2 / 2 </k> [all-path]

  // ==========================================================================
  // (EXPAND-LOG1)  expand_func(polylog(1, Z)) = -log(1 - Z), free symbol Z.
  //   No exp_polar(-I*pi) factor.  Z stays a free variable (no eval rule matches
  //   a symbolic z), so this is genuinely an opt-in symbolic identity.
  // SPEC-PROVENANCE:
  //   from_prompt: "Why does the expansion of polylog(1, z) have exp_polar(-I*pi)?
  //                 ... polylog(1, z) and -log(1-z) are exactly the same function"
  // ==========================================================================
  claim <k> expand(polylog(1, Z:Expr)) => neg(log(1 - Z)) </k>         [all-path]

endmodule
