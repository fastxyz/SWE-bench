// polylog-spec.k — K reachability claims (the formal proof obligations) for the
// audited `polylog` behavior, over the mini-sympy.k semantics.
//
// STATUS: CONSTRUCTED, NOT MACHINE-CHECKED.
//
// Naming: uppercase logical variables (S, Z, N, ACC) are symbolic; lowercase
// names in mini-sympy are program constructors. Each claim carries
// SPEC-PROVENANCE tying it to public intent (the issue text + the docstring +
// the established dilogarithm special values + the existing eval convention).

module POLYLOG-SPEC
  imports MINI-SYMPY

  // thetaPow(K, A) = theta applied K times to A; the intended value of the
  // s<=0 loop (theta has no closed form simpler than its own iteration, so this
  // claim certifies *termination + exact iteration count*, not an arithmetic
  // identity).  Used only by (LOOP).
  syntax Expr ::= "thetaPow" "(" Int "," Expr ")"
  rule thetaPow(0, A) => A
  rule thetaPow(N, A) => thetaPow(N -Int 1, theta(A))  requires N >Int 0

  // ===================================================================
  // (EVAL-HALF)  THE CORE PLACEMENT OBLIGATION
  // Constructing polylog(2, 1/2) — with no opt-in transform — must already
  // yield the closed form on the construction/eval path.
  // SPEC-PROVENANCE:
  // - from_prompt: "Add evaluation for polylog ... The answer should be
  //                 -log(2)**2/2 + pi**2/12"
  // - from_prompt(form): the value is the *bare* result wanted for
  //                 polylog(2, Rational(1,2)); fvk_materials/.../formalize.md
  //                 Step 2 names this exact case — the unevaluated Out[1] is the
  //                 SYMPTOM, not an invariant, so the obligation is on eval.
  // - from_default_domain: special values auto-evaluate in eval
  //                 (cf. zeta(2)=>pi**2/6, dirichlet_eta(2)=>pi**2/12).
  // ===================================================================
  claim <k> mkPolylog(2, oneHalf) => li2Half </k>   // [all-path]

  // (EVAL-HALF-COROLLARY) the value is NEVER left as a symbolic polylog:
  // plog(2, oneHalf) is unreachable from construction.  (Same redex as above:
  // eval-half fires before the eval-frame owise rule can.)
  claim <k> mkPolylog(2, oneHalf) => li2Half </k>
    ensures notBool (li2Half ==K plog(2, oneHalf))

  // ===================================================================
  // (EVAL-Z1/ZM1/Z0)  pre-existing special-z evaluations are PRESERVED.
  // SPEC-PROVENANCE:
  // - from_docs: polylog docstring "For z in {0,1,-1}, the polylogarithm is
  //              automatically expressed using other functions".
  // - from_public_test: test_polylog_expansion asserts these three.
  // ===================================================================
  claim <k> mkPolylog(S, 1)  => zetaE(S)       </k>   // [all-path]
  claim <k> mkPolylog(S, -1) => Neg(detaE(S))  </k>   // [all-path]
  claim <k> mkPolylog(S, 0)  => 0              </k>   // [all-path]

  // ===================================================================
  // (EVAL-SYM-FRAME)  NO spurious construction-time evaluation.
  // For a symbolic z (any s), polylog(s, z) stays symbolic.  This is what lets
  // polylog(s, z) remain a usable symbolic object (derivative test td(polylog
  // (b, z), z), rewrite, series, ...).  The (2,1/2) eval must NOT leak to
  // symbolic z.
  // SPEC-PROVENANCE:
  // - from_public_test: test_derivatives `td(polylog(b, z), z)` needs a live
  //                     symbolic polylog.
  // - from_code: eval returns None for non-special (s, z).
  // ===================================================================
  claim <k> mkPolylog(S, Z:Id) => plog(S, Z) </k>     // [all-path]

  // ===================================================================
  // (EXPAND-S1)  THE CORE BRANCH-CUT OBLIGATION
  // expand_func(polylog(1, z)) == -log(1 - z), with NO exp_polar factor.
  // SPEC-PROVENANCE:
  // - from_prompt: "polylog(1, z) and -log(1-z) are exactly the same function
  //                 ... I don't see a reason for exp_polar here".
  // - from_prompt: derivative consistency — expand_func(diff(polylog(1,z)
  //                 - expand_func(polylog(1,z)), z)) must be 0.
  // ===================================================================
  claim <k> expandFunc(plog(1, Z)) => Neg(logE(Sub(1, Z))) </k>   // [all-path]

  // ===================================================================
  // (EXPAND-S0)  the s == 0 elementary reduction still reaches the loop body
  // with zero iterations (theta^0): expand_func(polylog(0, z)) = (u/(1-u))|u=z.
  // SPEC-PROVENANCE:
  // - from_public_test: test_polylog_expansion `myexpand(polylog(0, z),
  //                     z/(1 - z))`.
  // - from_code: the `s.is_Integer and s <= 0` branch, range(-0) empty.
  // ===================================================================
  claim <k> expandFunc(plog(0, Z)) => subU(base, Z) </k>          // [all-path]

  // ===================================================================
  // (EXPAND-SYM-FRAME)  expand_func leaves a non-reducible polylog unchanged
  // (e.g. symbolic order s): no spurious rewrite, no exp_polar appears anywhere.
  // ===================================================================
  claim <k> expandFunc(plog(S:Id, Z)) => plog(S, Z) </k>         // [all-path]

  // ===================================================================
  // (LOOP)  the for-loop circularity for the integer s<=0 branch.
  // Generalized over the counter N (= -s) and accumulator ACC; soundness side
  // condition N >= 0.  Certifies termination + exactly N theta-applications.
  // This branch is UNCHANGED by the fix; the claim documents that it is
  // correctly gated (only integer s <= 0) and total on N >= 0.
  // SPEC-PROVENANCE:
  // - from_code: `for _ in range(-s): start = u*start.diff(u)`.
  // - from_default_domain: range(-s) iterates -s>=0 times for integer s<=0.
  // ===================================================================
  claim <k> runTheta(N, ACC) => thetaPow(N, ACC) </k>
    requires N >=Int 0                                            // [all-path]
endmodule
