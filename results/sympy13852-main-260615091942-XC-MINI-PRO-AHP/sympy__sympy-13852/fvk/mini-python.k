// mini-python.k
// ---------------------------------------------------------------------------
// Minimal K semantics for the fragment of sympy's
//   sympy/functions/special/zeta_functions.py :: polylog._eval_expand_func
// that the V1 fix touches.  We model `_eval_expand_func` as a TERM-REWRITING
// dispatch over symbolic SymPy expressions: the observable the fix manipulates
// is the *shape of the returned expression*, so the model's observable is a
// symbolic Expr (not an Int accumulator).  This keeps the verified property
// representable (formalize.md step 3: "minimal, but still property-complete").
//
// MVP stopgap: this is a faithful fragment, NOT full SymPy/Python-in-K.  It
// covers only the constructs `_eval_expand_func` actually uses for the
// branches under audit (integer order `s`, the symbol `z`, the rational 1/2,
// log/pi/arithmetic constructors) plus exp_polar/I purely so the *old* (buggy)
// V0 output form can be named and contrasted.
// ---------------------------------------------------------------------------

module MINI-PYTHON-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  // Symbolic SymPy expression terms.
  syntax Expr ::= Int                              // integer literals (also the order s)
                | "z"                              // a free complex Symbol('z')
                | "half"                           // the rational 1/2  (S.Half)
                | "piC"                            // pi
                | "Iunit"                          // the imaginary unit I
                | "logE" "(" Expr ")"              // log(_)
                | "polylog" "(" Expr "," Expr ")"  // polylog(s, z)
                | "neg" "(" Expr ")"               // -_
                | "add" "(" Expr "," Expr ")"      // _ + _
                | "sub" "(" Expr "," Expr ")"      // _ - _
                | "mul" "(" Expr "," Expr ")"      // _ * _
                | "divE" "(" Expr "," Expr ")"     // _ / _
                | "powE" "(" Expr "," Expr ")"     // _ ** _
                | "expPolar" "(" Expr ")"          // exp_polar(_)  (old V0 form ONLY)

  // The modeled function and the helpers for the s<=0 branch.
  syntax Expr ::= "expandPL" "(" Expr ")"          [function]   // _eval_expand_func
                | "iterD" "(" Int "," Expr ")"     [function]   // the  for _ in range(-s)  loop
                | "applyDn" "(" Int "," Expr ")"   [function]   // spec-side N-fold application
                | "applyD" "(" Expr ")"            // one  start = u*start.diff(u)  step (abstract)
                | "seed"                           // start = u/(1 - u)
                | "substZ" "(" Expr ")"            // .subs(u, z)
endmodule

module MINI-PYTHON
  imports MINI-PYTHON-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:Expr </k>

  // ====== dispatch of _eval_expand_func, faithful to the source order ======
  // The Python is a sequence of `if`s with early `return`; the four rules
  // below are made mutually exclusive (specific patterns + [owise]) so the
  // model is confluent and the "first matching branch" semantics is preserved.

  // ---- Branch 1 :  if s == 1: return -log(1 - z)        [CHANGED by V1] ----
  // V0 returned  -log(1 + exp_polar(-I*pi)*z); V1 returns -log(1 - z).
  rule expandPL(polylog(1, Z:Expr)) => neg(logE(sub(1, Z)))

  // ---- Branch 2 :  if s.is_Integer and s <= 0: <rational fn>   [UNCHANGED] -
  // start = u/(1-u); for _ in range(-s): start = u*start.diff(u);
  // return expand_mul(start).subs(u, z)
  rule expandPL(polylog(S:Int, Z:Expr)) => substZ(iterD(0 -Int S, seed))
       requires S <=Int 0

  // ---- Branch 3 :  if s == 2 and z == S.Half: dilog value      [ADDED by V1]
  //      return -log(2)**2/2 + pi**2/12
  rule expandPL(polylog(2, half))
       => add(neg(divE(powE(logE(2), 2), 2)), divE(powE(piC, 2), 12))

  // ---- Branch 4 :  return polylog(s, z)   (stays symbolic)     [UNCHANGED] -
  // Fires only when none of branches 1-3 matched (e.g. s>=3, or s==2 & z!=1/2,
  // or non-integer s).  This is the SymPy default: leave the call unevaluated.
  rule expandPL(polylog(S, Z)) => polylog(S, Z)   [owise]

  // ====== the s<=0 counting loop (Branch 2 internals) ======================
  // iterD(N, T) applies `applyD` exactly N times (N = -s >= 0), innermost-first.
  rule iterD(N:Int, T:Expr) => iterD(N -Int 1, applyD(T)) requires N >Int 0
  rule iterD(0, T:Expr) => T

  // spec-side reference: the same N-fold application, outermost-last.
  rule applyDn(N:Int, T:Expr) => applyD(applyDn(N -Int 1, T)) requires N >Int 0
  rule applyDn(0, T:Expr) => T
endmodule
