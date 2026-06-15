// mini-cas.k — a minimal "mini-X" K semantics for the slice of SymPy's symbolic
// CAS that the polylog code under audit actually touches.
//
// FVK note: this is a deliberate fragment (a stopgap for a full Python-in-K +
// SymPy-in-K semantics — see fvk_materials/README.md "Honest status"). It models
// ONLY what `polylog.eval`, `polylog._eval_expand_func`, `polylog.fdiff`, the main
// `simplify`, and the issue's reproduction expressions use, and nothing else.
//
// SymPy's evaluation is itself term rewriting, so it maps onto K naturally:
//   * polylog.eval            -> rewrite rules that fire eagerly at construction
//   * polylog._eval_expand_func-> rewrite rules under an `expandf(_)` marker
//   * polylog.fdiff           -> rewrite rules under a `der(_)` marker (d/dz)
//   * simplify                -> the main-path fact that it does NOT expand_func a polylog
//
// Status: CONSTRUCTED, NOT MACHINE-CHECKED (kompile/kprove not run in this env).
// The transcendental special-function identities (Li_1, Li_2(1/2)) are stated as
// [ESCALATION BOUNDARY] lemmas — see polylog-spec.k and PROOF.md — never [trusted].

module MINI-CAS-SYNTAX
  imports INT-SYNTAX
  imports ID-SYNTAX

  // Symbolic expressions. Prefix constructors only (no operator precedence to get
  // wrong). Rational 1/2 is the literal atom `half` (models SymPy's S.Half).
  syntax Exp ::= Int | "pi" | "half" | Id          // atoms: ints, pi, 1/2, symbols z/s
               | "neg"  "(" Exp ")"                 // unary minus
               | "add"  "(" Exp "," Exp ")"
               | "sub"  "(" Exp "," Exp ")"
               | "mul"  "(" Exp "," Exp ")"
               | "divi" "(" Exp "," Exp ")"
               | "powr" "(" Exp "," Exp ")"
               | "log"  "(" Exp ")"
               | "zeta" "(" Exp ")"
               | "deta" "(" Exp ")"                 // dirichlet_eta
               | "polylog" "(" Exp "," Exp ")"
               // operations (markers), strict so their argument normalises first:
               | "expandf" "(" Exp ")"   [strict]   // sympy expand_func / .expand(func=True)
               | "simpl"   "(" Exp ")"   [strict]   // sympy simplify
               | "der"     "(" Exp ")"   [strict]   // d/dz

  // Everything that is not an unreduced operation marker is a value (normal form).
  // (Abstraction: a symbolic CAS has no single "KResult" sort; we treat reduced
  //  symbolic trees as results. Faithful enough for the rewrite obligations here.)
  syntax KResult ::= Exp
endmodule

module MINI-CAS
  imports MINI-CAS-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:Exp </k>

  // Convenience macros for the two closed forms the issue names.
  //   CF2  = pi^2/12 - log(2)^2/2          (= Li_2(1/2))
  //   LOG1 = -log(1 - z)                   (= Li_1(z))
  syntax Exp ::= "CF2" [macro] | "LOG1" "(" Exp ")" [macro]
  rule CF2     => sub(divi(powr(pi,2), 12), divi(powr(log(2),2), 2))
  rule LOG1(Z) => neg(log(sub(1, Z)))

  // ===================================================================
  // polylog.eval  — SymPy auto-evaluation performed at construction time.
  // These mirror the `eval` classmethod EXACTLY (zeta_functions.py).
  // SPEC-PROVENANCE:
  //  - from_code:  z in {1,-1,0} -> zeta(s) / -dirichlet_eta(s) / 0  (pre-existing)
  //  - from_prompt(#7132 "Add evaluation for polylog"): the (s=2, z=1/2) value [V2 NEW]
  //  - from_public_test(test_wester.test_R18, simplify-path) + intent-note
  //    ("do not enshrine 'stays unevaluated by default'"): the value must be on the
  //    CONSTRUCTION path, not only under expand_func.
  // ===================================================================
  rule <k> polylog(S:Exp, 1)       => zeta(S)        ... </k>
  rule <k> polylog(S:Exp, neg(1))  => neg(deta(S))   ... </k>
  rule <k> polylog(_:Exp, 0)       => 0              ... </k>
  rule <k> polylog(2, half)        => CF2            ... </k>           // [V2 NEW]

  // ===================================================================
  // polylog._eval_expand_func — closed-form expansions, under expand_func.
  // Mirror _eval_expand_func. Reachable for a polylog built evaluate=False (so the
  // eval rule above did not fire) and via simplify's `hypersimp` path.
  // ===================================================================
  rule <k> expandf(polylog(1, Z:Exp)) => LOG1(Z) ... </k>              // s=1, ALL z  [part-2 fix: NO exp_polar]
  rule <k> expandf(polylog(2, half))  => CF2      ... </k>             // s=2, z=1/2  (evaluate=False path)
  rule <k> expandf(polylog(0, Z:Exp)) => divi(Z, sub(1, Z)) ... </k>   // s=0  (representative of s<=0; unchanged by fix)

  // expand_func recurses structurally and is the identity on everything else.
  rule <k> expandf(neg(A))      => neg(expandf(A))            ... </k>
  rule <k> expandf(add(A,B))    => add(expandf(A), expandf(B))... </k>
  rule <k> expandf(sub(A,B))    => sub(expandf(A), expandf(B))... </k>
  rule <k> expandf(mul(A,B))    => mul(expandf(A), expandf(B))... </k>
  rule <k> expandf(divi(A,B))   => divi(expandf(A), expandf(B))...</k>
  rule <k> expandf(log(A))      => log(A)                     ... </k> // log has no _eval_expand_func
  rule <k> expandf(A:Exp)       => A                          ... </k> [owise]

  // ===================================================================
  // simplify — MAIN PATH.  Key modelled fact (simplify.py): the top-level
  // `simplify` does NOT call expand_func on a polylog (the only expand_func call
  // lives inside `hypersimp`). So simplify leaves a *bare* polylog unchanged; it only
  // returns an already-closed-form expression as-is (closed forms here are stable).
  // ===================================================================
  rule <k> simpl(A:Exp) => A ... </k>

  // ===================================================================
  // derivative d/dz — SymPy polylog.fdiff(argindex=2): d/dz polylog(s,z)=polylog(s-1,z)/z
  // plus the ordinary chain/linearity rules needed for the issue's identity.
  // ===================================================================
  rule <k> der(polylog(S:Exp, Z:Exp)) => divi(polylog(sub(S,1), Z), Z) ... </k>
  rule <k> der(neg(A))   => neg(der(A))                 ... </k>
  rule <k> der(add(A,B)) => add(der(A), der(B))         ... </k>
  rule <k> der(sub(A,B)) => sub(der(A), der(B))         ... </k>
  rule <k> der(log(A))   => divi(der(A), A)             ... </k>
  rule <k> der(1) => 0 ... </k>
  rule <k> der(z) => 1 ... </k>
endmodule
