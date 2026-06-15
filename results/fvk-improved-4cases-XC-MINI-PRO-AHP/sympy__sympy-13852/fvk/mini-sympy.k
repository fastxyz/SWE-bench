// mini-sympy.k  —  CONSTRUCTED, NOT MACHINE-CHECKED
//
// A minimal K semantics for *exactly* the fragment of SymPy exercised by
//   polylog._eval_expand_func   (repo/sympy/functions/special/zeta_functions.py)
// and by the `polylog.fdiff` derivative rule that the public issue uses as its
// correctness oracle.  Nothing else from SymPy is modelled.
//
// Why this shape: the function under audit is a *pure, finite case dispatcher*
// over the pair (s, z).  There is no mutable store and only one loop in the
// whole method (the `for _ in range(-s)` in the s<=0 branch, which the fix does
// NOT touch — see ratPolylog below).  So the contract is a set of reachability
// rules `expandPolylog(s,z) => <result>`, plus a tiny structural-differentiation
// fragment so we can state the issue's key property:
//   d/dz of the expansion of polylog(1,z) must equal d/dz of polylog(1,z).
// The OLD code returned  -log(1 + exp_polar(-I*pi)*z), whose derivative does NOT
// reduce to 1/(1-z); the FIX returns -log(1 - z), whose derivative does.

module MINI-SYMPY-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports ID-SYNTAX

  // A tiny symbolic-expression algebra.  Only the constructors the proof needs.
  syntax Expr ::= Int                                   // integer literal (also models s)
                | Id                                     // a symbolic program variable, e.g. z
                | "Pi"                                   // the constant pi
                | "Half"                                 // the rational 1/2  (SymPy S.Half)
                | "Log"  "(" Expr ")"                    // natural logarithm
                | "PolyLog" "(" Expr "," Expr ")"        // unevaluated polylog(s, z)
                | "ratPolylog" "(" Int "," Expr ")"      // s<=0 branch result (abstracted; see below)
                | "expandPolylog" "(" Expr "," Expr ")"  // the method under audit
                | "Diff" "(" Expr "," Id ")"             // d/dId (structural)
                > "Pow"  "(" Expr "," Expr ")"  [klabel(powE), function]
                | "Mul"  "(" Expr "," Expr ")"  [klabel(mulE), function]
                | "Div"  "(" Expr "," Expr ")"  [klabel(divE), function]
                > "Sub"  "(" Expr "," Expr ")"  [klabel(subE), function]
                | "Add"  "(" Expr "," Expr ")"  [klabel(addE), function]
                | "Neg"  "(" Expr ")"           [klabel(negE), function]

  syntax KResult ::= Int
endmodule

module MINI-SYMPY
  imports MINI-SYMPY-SYNTAX
  imports INT
  imports BOOL

  // The whole computation is a single expression to normalise.
  configuration <k> $PGM:Expr </k>

  // =====================================================================
  // polylog._eval_expand_func(self):  s, z = self.args
  // The four return paths, transcribed rule-for-rule from the source.
  // =====================================================================

  // SOURCE:  if s == 1: return -log(1 - z)                 [FIX — exp_polar dropped]
  rule <k> expandPolylog(1, Z:Expr) => Neg(Log(Sub(1, Z))) </k>

  // SOURCE:  if s == 2 and z == S.Half: return -log(2)**2/2 + pi**2/12   [NEW value]
  rule <k> expandPolylog(2, Half) => Add(Neg(Div(Pow(Log(2), 2), 2)), Div(Pow(Pi, 2), 12)) </k>

  // SOURCE:  if s.is_Integer and s <= 0: <loop> return expand_mul(start).subs(u, z)
  //   The loop `start = u/(1-u); for _ in range(-s): start = u*start.diff(u)` is
  //   UNCHANGED by the fix.  We abstract its result as ratPolylog(s, z) and pin
  //   the only concrete instance the public tests touch, s = 0  ->  z/(1 - z)
  //   (the loop body runs range(0) = 0 times, so start is returned verbatim).
  rule <k> expandPolylog(S:Int, Z:Expr) => ratPolylog(S, Z) </k> requires S <=Int 0
  rule <k> ratPolylog(0, Z:Expr) => Div(Z, Sub(1, Z)) </k>

  // SOURCE:  return polylog(s, z)                          [fallback, unchanged]
  //   Reached by: symbolic s; integer s >= 3; s == 2 with z != 1/2.  `[owise]`
  //   models "no earlier branch returned", exactly the Python fall-through.
  rule <k> expandPolylog(S:Expr, Z:Expr) => PolyLog(S, Z) </k> [owise]

  // =====================================================================
  // polylog.fdiff:  d/dz polylog(s, z) = polylog(s-1, z)/z
  // plus the handful of elementary derivative rules the consistency proof uses.
  // These are structural rewrites (apply to any matching subterm).
  // =====================================================================
  rule Diff(PolyLog(S:Int, Z:Id), Z) => Div(PolyLog(S -Int 1, Z), Z)
  rule Diff(Z:Id, Z)                  => 1
  rule Diff(N:Int, _:Id)             => 0
  rule Diff(Neg(E:Expr), X:Id)       => Neg(Diff(E, X))
  rule Diff(Sub(A:Expr, B:Expr), X)  => Sub(Diff(A, X), Diff(B, X))
  rule Diff(Log(E:Expr), X:Id)       => Div(Diff(E, X), E)

  // =====================================================================
  // Normalisation lemmas for the tiny algebra (function rules above are
  // `[function]`, so these fire eagerly wherever they match).  Each is a true
  // identity of the rationals/reals; together they put the consistency goal in
  // the canonical form  Div(1, Sub(1, Z)).
  // =====================================================================
  rule Sub(0, 1)            => Neg(1)              // 0 - 1 = -1
  rule Neg(Neg(E:Expr))     => E                   // --E = E
  rule Neg(Div(Neg(E:Expr), F:Expr)) => Div(E, F)  // -(-E / F) = E / F
  rule Div(Div(Z:Id, F:Expr), Z)     => Div(1, F)  // (Z/F)/Z = 1/F   (Z != 0 in-domain)
endmodule
