// mini-sympy.k — a minimal K fragment of just the constructs sympy's `polylog`
// dispatch actually uses: construction-time `eval(s, z)`, `expand_func` on a
// polylog, and the integer-`s <= 0` "theta loop" inside `_eval_expand_func`.
//
// This is a deliberate "mini-X" placeholder for a full Python-in-K semantics
// (see fvk_materials/commands/formalize.md, step 3). It models term
// construction + conditional dispatch (which is exactly what `eval` /
// `_eval_expand_func` are) as K rewrite rules, because K is itself a
// term-rewriting engine. Only what the audited code touches is modelled.
//
// STATUS: CONSTRUCTED, NOT MACHINE-CHECKED (no kompile/kprove was run).

module MINI-SYMPY-SYNTAX
  imports INT-SYNTAX
  imports ID-SYNTAX

  // ---- symbolic expressions (the only data the code manipulates) ----
  // Integer literals model the integer arguments s (1, 2, 0, negatives) and
  // the special z values 0, 1, -1. `oneHalf` models the Rational 1/2.
  // Everything else needed for the *results* is a prefix constructor so that
  // there are no operator-precedence subtleties: structural equality of result
  // trees is all the proof needs.
  syntax Expr ::= Int                        // integer literal  (also subsorts s, z)
                | Id                          // a free symbol, e.g. z, s
                | "oneHalf"                   // the rational 1/2
                | "piC"                       // the constant pi
                | "zetaE"   "(" Expr ")"      // zeta(s)
                | "detaE"   "(" Expr ")"      // dirichlet_eta(s)
                | "logE"    "(" Expr ")"      // log(.)
                | "plog"    "(" Expr "," Expr ")"  // the *symbolic* polylog(s, z)
                | "Neg"     "(" Expr ")"      // unary minus
                | "Add"     "(" Expr "," Expr ")"
                | "Mul"     "(" Expr "," Expr ")"
                | "Sub"     "(" Expr "," Expr ")"  // a - b
                | "Pow"     "(" Expr "," Int ")"
                | "Div"     "(" Expr "," Int ")"   // a / n   (n an integer)
                | "theta"   "(" Expr ")"      // the operator u * d/du (abstract)
                | "base"                      // u/(1-u)  (the Dummy seed; abstract)

  // ---- the functions under audit, as explicit "driver" constructs ----
  syntax Expr ::= "mkPolylog"   "(" Expr "," Expr ")"  // polylog(s, z): runs eval
                | "expandFunc"  "(" Expr ")"           // expand_func(polylog(s,z))
                | "expandNonpos" "(" Int "," Expr ")"  // the s<=0 branch body
                | "runTheta"    "(" Int "," Expr ")"   // for _ in range(-s): ...
                | "subU"        "(" Expr "," Expr ")"  // .subs(u, z)  (abstract)
endmodule

module MINI-SYMPY
  imports MINI-SYMPY-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:Expr </k>

  // li2Half := -log(2)**2/2 + pi**2/12          (the dilogarithm value Li_2(1/2))
  // Kept as a named macro so the closed form is visible to the spec audit while
  // the dispatch claims can refer to it by name.
  syntax Expr ::= "li2Half"  [macro]
  rule li2Half => Add( Neg(Div(Pow(logE(2), 2), 2)) , Div(Pow(piC, 2), 12) )

  // =====================================================================
  // CONSTRUCTION PATH:  polylog(s, z)  ==  classmethod eval(s, z)
  //   eval returns a reduced term for special (s,z); otherwise it returns
  //   None, which the Function machinery turns into the symbolic plog(s,z).
  //   SPEC-PROVENANCE:
  //   - from_code: zeta_functions.py polylog.eval (z in {0,1,-1}; new (2,1/2))
  //   - from_prompt: "Add evaluation for polylog ... The answer should be
  //                   -log(2)**2/2 + pi**2/12"  => bare-construction obligation
  //   - from_default_domain: special values auto-evaluate in eval, exactly as
  //                   zeta(2)=>pi**2/6, dirichlet_eta(2)=>pi**2/12 do
  // =====================================================================
  rule mkPolylog(S, 1)       => zetaE(S)          [eval-z1]
  rule mkPolylog(S, -1)      => Neg(detaE(S))     [eval-zm1]
  rule mkPolylog(_, 0)       => 0                 [eval-z0]
  rule mkPolylog(2, oneHalf) => li2Half           [eval-half]   // <-- V2 placement
  // frame: eval returned None for every other (s, z), so the symbolic polylog
  // survives unchanged. `[owise]` fires only when none of the rules above match.
  rule mkPolylog(S, Z) => plog(S, Z)              [eval-frame] [owise]

  // =====================================================================
  // OPT-IN PATH:  expand_func(polylog(s, z))  ==  _eval_expand_func(self)
  //   SPEC-PROVENANCE:
  //   - from_code: zeta_functions.py polylog._eval_expand_func
  //   - from_prompt: "expand_func(polylog(1, z)) ... I don't see a reason for
  //                   exp_polar here" => result must be -log(1 - z), no exp_polar
  // =====================================================================
  rule expandFunc(plog(1, Z)) => Neg(logE(Sub(1, Z)))           [expand-s1]
  rule expandFunc(plog(S:Int, Z)) => expandNonpos(S, Z)
    requires S <=Int 0                                          [expand-nonpos]
  rule expandFunc(plog(S, Z)) => plog(S, Z)                     [expand-frame] [owise]

  // the s<=0 body:
  //   start = u/(1-u); for _ in range(-s): start = u*start.diff(u); subs(u,z)
  // theta(E) abstracts the one-line body  E := u*E.diff(u).
  rule expandNonpos(S, Z) => subU( runTheta(0 -Int S, base), Z ) [nonpos-body]

  // the for-loop over range(-s)  (a genuine counting loop -> a circularity):
  rule runTheta(0, Acc) => Acc                                  [loop-base]
  rule runTheta(N, Acc) => runTheta(N -Int 1, theta(Acc))
    requires N >Int 0                                           [loop-step]
endmodule
