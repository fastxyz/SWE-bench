// polylog-spec.k
// ---------------------------------------------------------------------------
// K reachability `claim`s for the V1 fix of
//   polylog._eval_expand_func  (sympy/functions/special/zeta_functions.py).
//
// Each claim is a function-contract reachability rule  phi_pre => phi_post
// over the mini-python.k dispatch semantics.  The branches under audit
// (s==1 and s==2&z==1/2) are straight-line dispatch, so they are non-loop
// reachability rules; the s<=0 branch carries a counting-loop circularity.
//
// IMPORTANT (adequacy split): a K claim here proves only that `expandPL`
// REWRITES to the stated TERM (dispatch soundness).  That the term is the
// mathematically correct value of Li_s(z) is a separate, number-theoretic
// obligation discharged in PROOF.md (reflection formula / textbook identity /
// branch-cut argument), then cross-checked in SPEC_AUDIT (PROOF.md section).
// Labeled "constructed, not machine-checked."
// ---------------------------------------------------------------------------

module POLYLOG-SPEC
  imports MINI-PYTHON

  // ---- (POLYLOG-S1) : the exp_polar removal, issue Part 2 -----------------
  // SPEC-PROVENANCE:
  // - from_prompt: "Why does the expansion of polylog(1, z) have exp_polar(-I*pi)?
  //                 ... polylog(1, z) and -log(1-z) are exactly the same function"
  //                 => expand_func(polylog(1,z)) must be -log(1-z), exp_polar-free.
  // - from_prompt: "expand_func(diff(polylog(1, z) + log(1 - z), z))  # 0"
  //                 => derivative consistency requires the -log(1-z) form.
  // - from_docs_or_tests: hyperexpand(z*hyper([1,1],[2],z)) == -log(1 + -z)
  //                 (test_hyperexpand.py:582) => the library's own canonical form
  //                 for this object is -log(1-z).
  // - conflicts: test_zeta_functions.py:131 asserts the OLD exp_polar form
  //                 -> SUSPECT legacy test (encodes the reported bug); see FINDINGS.
  claim <k> expandPL(polylog(1, z)) => neg(logE(sub(1, z))) </k>   [one-path]

  // ---- (POLYLOG-DILOG-HALF) : the dilogarithm value, issue Part 1 ---------
  // SPEC-PROVENANCE:
  // - from_prompt: "polylog(2, Rational(1,2)).expand(func=True) ...
  //                 The answer should be -log(2)**2/2 + pi**2/12"
  //                 => expand_func must yield this closed form for s=2, z=1/2.
  // - from_default_domain: dilogarithm reflection law Li2(z)+Li2(1-z) =
  //                 pi^2/6 - log(z)log(1-z); at z=1/2 gives Li2(1/2)=pi^2/12-log(2)^2/2.
  // - from_code: returned via _eval_expand_func (the .expand(func=True) path),
  //                 NOT eval -- the value is shown under a transform (issue In[2]),
  //                 so it binds under that transform (intent-evidence.md sec.3, "form").
  claim <k> expandPL(polylog(2, half))
         => add(neg(divE(powE(logE(2), 2), 2)), divE(powE(piC, 2), 12)) </k>  [one-path]

  // ---- (POLYLOG-DEFAULT) : the new branch does not over-fire (s>=3) --------
  // SPEC-PROVENANCE:
  // - from_intent: fix must be TARGETED; orders other than the specified ones
  //                must keep returning polylog(s,z) unchanged (no regression).
  // - from_docs_or_tests: test_hyperexpand.py:583-584 keep polylog(2,z)/polylog(3,z)
  //                symbolic; :608 keeps polylog(3, S(1)/2) symbolic.
  claim <k> expandPL(polylog(3, z)) => polylog(3, z) </k>          [one-path]

  // ---- (POLYLOG-DILOG-NONHALF) : dilog rule fires ONLY at z==1/2 -----------
  // SPEC-PROVENANCE:
  // - from_intent: the special value is for z=1/2 only; symbolic z must stay
  //                polylog(2, z) (general dilog has no elementary closed form).
  claim <k> expandPL(polylog(2, z)) => polylog(2, z) </k>          [one-path]

  // ---- (LOOP) : the s<=0 counting loop terminates & applies applyD N times --
  // Branch 2 is UNCHANGED by the fix; this circularity shows the loop runs
  // exactly N = -s steps (termination + count).  The mathematical content
  // (applyD = u*d/du, and applyD^N(u/(1-u))|_{u=z} = Li_{-N}(z)) is inherited
  // from existing passing tests (test_polylog_expansion) -- a trusted-base item.
  // SPEC-PROVENANCE:
  // - from_code: for _ in range(-s): start = u*start.diff(u)
  // - from_docs_or_tests: polylog(0,z)->z/(1-z); polylog(-1,z)->z^2/(1-z)^2+z/(1-z)
  claim <k> iterD(N:Int, T:Expr) => applyDn(N, T) </k>
        requires N >=Int 0                                        [one-path]
endmodule
