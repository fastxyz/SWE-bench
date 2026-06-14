// mini-pyoo.k — minimal K semantics of the Python-OO fragment that sympy #12489 touches.
// Models ONLY: dynamic-class stamping (Basic.__new__(cls, perm)), classmethod/instance
// dispatch (the cls/self binding), isinstance, and the Permutation.__new__ case split.
// The permutation-VALUE functions (invertA, rmulA, mkrange, normA, isPerm, isCyc) are
// left OPAQUE on purpose: PO-3 (value preservation) is discharged syntactically in
// PROOF.md §4, so the class-tag proof treats them as uninterpreted.
//
// STATUS: constructed, NOT machine-checked (no K toolchain available in this environment).

module MINI-PYOO-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports LIST
  imports ID-SYNTAX

  syntax Class ::= Id                                 // class names: Permutation, Sub, ...
  syntax Obj   ::= "obj" "(" Class "," List ")"       // a Permutation / subclass instance
  syntax Val   ::= Obj | Int | List | Class | Bool

  // expression forms that actually appear in the fixed source (and nothing else)
  syntax Exp ::= Val
       | "Basic_new" "(" Exp "," Exp ")"   [strict]    // Basic.__new__(cls, perm)
       | Exp "._af_new" "(" Exp ")"        [strict]    // the @classmethod factory
       | "newP"  "(" Exp "," Exp ")"       [strict]    // Permutation.__new__(cls, arg)
       | "inv"   "(" Exp ")"               [strict]    // ~p              (__invert__)
       | Exp "*" Exp                       [strict]    // p * q           (__mul__)
       | "rmul"  "(" Exp "," Exp ")"       [strict(2)] // other * self    (__rmul__)
       | "cctor" "(" Exp "," Exp ")"       [strict]    // random/unrank_*/from_inversion_vector
       | "josephus" "(" Exp "," Exp ")"    [strict]    // C.josephus(...)
       | "fromseq"  "(" Exp "," Exp ")"    [strict]    // C.from_sequence(i)
       | "iunrank"  "(" Exp "," Exp ")"    [strict]    // self.unrank_*  (__add__/__sub__/next_nonlex)

  // opaque value functions (uninterpreted; see PROOF.md §4)
  syntax List ::= "invertA" "(" List ")"          [function]
                | "rmulA"   "(" List "," List ")" [function]
                | "mkrange" "(" Int ")"           [function]
                | "normA"   "(" List ")"          [function]
  syntax Bool ::= "isPerm"  "(" List ")"          [function]
                | "isCyc"   "(" List ")"          [function]

  // class-lattice + reflection helpers
  syntax Class ::= "classOf" "(" Val ")"           [function]
  syntax Bool  ::= "isinst"  "(" Val "," Class ")" [function]
                 | "subq"    "(" Class "," Class ")" [function]

  syntax KResult ::= Val
endmodule

module MINI-PYOO
  imports MINI-PYOO-SYNTAX
  imports INT
  imports BOOL
  imports LIST

  // --- class lattice: one symbolic strict subclass is enough for the proof ---
  // Permutation <=: Permutation ;  Sub <=: Permutation ;  Sub <=: Sub ;  ¬(Permutation <=: Sub)
  rule subq(C, C)             => true
  rule subq(Sub, Permutation) => true
  rule subq(Permutation, Sub) => false
  rule classOf(obj(C, _))     => C
  rule isinst(obj(D, _), C)   => subq(D, C)

  // --- the ONE class-stamping primitive (sympy/core/basic.py:80) ------------
  rule Basic_new(C:Class, P:List) => obj(C, P)

  // --- _af_new is a @classmethod: cls is the receiver's class --------------
  rule (C:Class) ._af_new (P:List) => Basic_new(C, P)     // C._af_new / cls._af_new
  rule obj(C, _) ._af_new (P:List) => Basic_new(C, P)     // self._af_new (cls := classOf(self))

  // --- instance ops route through self._af_new -----------------------------
  rule inv(obj(C, A))         => obj(C, A) ._af_new (invertA(A))           // ~p, and *,**,^,mul_inv,…
  rule obj(C, A) * obj(_, B)  => obj(C, A) ._af_new (rmulA(A, B))          // left/self class wins

  // --- __rmul__ (V2 fix B2):  self.__class__(other) * self -----------------
  rule rmul(X:Int, obj(C, A)) => newP(C, X) * obj(C, A)

  // --- class-method constructors: self (= the class) is the stamp ----------
  rule cctor(C:Class, N:Int)    => C ._af_new (mkrange(N))                 // random/unrank_*/from_inversion_vector
  rule josephus(C:Class, N:Int) => newP(C, mkrange(N))                     // V1 fix: self(perm)
  rule fromseq(C:Class, I:List) => inv(newP(C, I))                         // V2 fix B3: ~self([...])

  // instance-routed classmethod ctor: cls := classOf(self)  [V2 fixes B4/B5]
  rule iunrank(obj(C, _), N:Int) => cctor(C, N)                            // __add__/__sub__ ; next_nonlex

  // --- Permutation.__new__(cls, arg) dispatch ------------------------------
  // shapes a (), c (cycle args), f (Cycle) are analogous to (b)/(d-e): each is
  // cls._af_new(<list>) ⇒ obj(C,…); modeled by the Int/List rules below.
  rule newP(C:Class, N:Int)     => C ._af_new (mkrange(N +Int 1))          // b  identity int   (also a: N=... empty)
  rule newP(C:Class, A:List)    => C ._af_new (normA(A))                   // a (A=.List) + d/e array/cyclic form
  rule newP(C:Class, obj(C, A)) => obj(C, A)                               // g-identity  (isinstance(a, cls))
  rule newP(C:Class, obj(D, A)) => C ._af_new (A)                          // g-rebuild   [V2 fix B1]
       requires notBool subq(D, C)
endmodule
