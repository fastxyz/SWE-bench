// mini-sympy.k  --  minimal K semantics of the SymPy fragment touched by the
// polylog fix (issue sympy/sympy#7132, "Add evaluation for polylog").
//
// CONSTRUCTED, NOT MACHINE-CHECKED.  This fragment models only the constructs
// the fix actually exercises:
//   * the polylog construction path  (classmethod `eval`, runs at __new__ time),
//   * `expand_func(...)`             (opt-in transform: `_eval_expand_func`),
//   * `simplify(...)`                (the relevant fact: it has NO expand_func step),
//   * `doit()` of the series  Sum_{k>=1} (1/2)^k / k^2   (== polylog(2, 1/2)).
//
// The *property axis* the change manipulates and the tests measure is:
//   "on which evaluation paths does polylog(2, 1/2) collapse to its closed form?"
// The model keeps that axis observable: the construction-path rule fires eagerly,
// so polylog(2, 1/2) is reduced no matter what wrapper (none / expand / simplify /
// doit) encloses it.  Dropping that rule (the V1 baseline) is faithfully a *different*
// observable, which is exactly how the bug shows up (see polylog-spec.k, claim R18).

module MINI-SYMPY-SYNTAX
  imports INT-SYNTAX

  syntax Expr ::= Int                                  // integer literals (lifted)
                | "pi"                                  // the constant pi
                | "half"                                // the rational 1/2
                | "log"           "(" Expr ")"
                | "zeta"          "(" Expr ")"
                | "dirichlet_eta" "(" Expr ")"
                | "neg"           "(" Expr ")"          // unary minus (avoids -lit parsing)
                > Expr "^" Expr   [left]
                > Expr "*" Expr   [left]
                | Expr "/" Expr   [left]
                > Expr "-" Expr   [left]
                | Expr "+" Expr   [left]
                // polylog(s, z): the OBJECT.  Its eval rules below model `polylog.eval`,
                // which SymPy runs during construction (__new__), eagerly.
                | "polylog"       "(" Expr "," Expr ")"
                // opt-in transforms and a summation-doit, made strict so the inner
                // (construction-path) reductions happen before the wrapper rule.
                | "expand"        "(" Expr ")"   [strict]
                | "simplify"      "(" Expr ")"   [strict]
                | "Li2sum_half"                         // doit() of Sum (1/2)^k/k^2
                | "(" Expr ")"                   [bracket]
endmodule

module MINI-SYMPY
  imports MINI-SYMPY-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:Expr </k>

  // ----------------------------------------------------------------------------
  // Construction path -- polylog.eval.  These fire eagerly on any polylog(...) term,
  // modelling that SymPy applies `eval` at object-construction time.
  // ----------------------------------------------------------------------------

  // [FIX]  SPEC-PROVENANCE  EVAL-DILOG
  //  from_prompt: "The answer should be -log(2)**2/2 + pi**2/12"
  //  from_public_test: test_wester.test_R18 reaches the value via .doit().simplify()
  //  obligation: a value at a *specific* argument (s=2, z=1/2) is an intrinsic
  //              constant -> it must collapse on the construction path, with NO
  //              opt-in call.  (This is the line V2 adds to polylog.eval.)
  rule polylog(2, half)     => pi ^ 2 / 12  -  log(2) ^ 2 / 2          [eval-dilog]

  // pre-existing construction-path special z-values (unchanged by the fix)
  rule polylog(_:Expr, 0)        => 0                                  [eval-z0]
  rule polylog(S:Expr, 1)        => zeta(S)                            [eval-z1]
  rule polylog(S:Expr, neg(1))   => neg(dirichlet_eta(S))             [eval-zm1]

  // doit() of  Sum_{k>=1} (1/2)^k / k^2  yields polylog(2, 1/2)
  // (per the comment on test_R18); the eval-dilog rule then collapses it.
  rule Li2sum_half          => polylog(2, half)                        [doit-sum]

  // ----------------------------------------------------------------------------
  // expand_func -- the opt-in transform (_eval_expand_func).  SYMBOLIC identities
  // in a free variable legitimately live here (may be undesirable to auto-apply).
  // ----------------------------------------------------------------------------

  // [FIX]  SPEC-PROVENANCE  EXPAND-LOG1
  //  from_prompt: "I don't see a reason for exp_polar here ... polylog(1,z) and
  //               -log(1-z) are exactly the same function"
  //  obligation: expand_func(polylog(1, Z)) = -log(1 - Z)  (no exp_polar factor).
  rule expand(polylog(1, Z:Expr)) => neg(log(1 - Z))                   [expand-log1]

  // expand_func is the identity on anything that is no longer a bare polylog
  // (e.g. the already-eval'd closed form): models `return polylog(s,z)` / no-op.
  rule expand(E:Expr) => E
       requires notBool isPolylog(E)                                   [expand-id]

  // ----------------------------------------------------------------------------
  // simplify -- models the operative fact about sympy.simplify for this issue:
  // its pipeline (powsimp/cancel/together/hyperexpand/trigsimp/...) contains NO
  // expand_func step, so a bare polylog it cannot otherwise reduce is left intact.
  // ----------------------------------------------------------------------------
  rule simplify(E:Expr) => E                                           [simplify-noexpand]

  // ----------------------------------------------------------------------------
  syntax Bool ::= isPolylog(Expr) [function]
  rule isPolylog(polylog(_, _)) => true
  rule isPolylog(_)             => false   [owise]
endmodule
