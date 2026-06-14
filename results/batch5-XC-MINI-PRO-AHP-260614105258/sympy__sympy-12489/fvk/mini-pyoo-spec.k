// mini-pyoo-spec.k — reachability claims for the sympy #12489 dynamic-class contract.
// Proves: every public construction/operation on a class C ⊑ Permutation yields an
// instance of C (fresh objects have classOf = C exactly), and at C := Permutation the
// behavior is unchanged (frame / PO-2).
//
// STATUS: constructed, NOT machine-checked. Run with the commands in PROOF.md §8.

requires "mini-pyoo.k"

module MINI-PYOO-SPEC-SYNTAX
  imports MINI-PYOO-SYNTAX
endmodule

module VERIFICATION
  imports MINI-PYOO-SPEC-SYNTAX
  imports MINI-PYOO
  imports K-EQUAL
endmodule

module MINI-PYOO-SPEC
  imports VERIFICATION

  // SPEC-PROVENANCE (all claims):
  //  - from_prompt(L1): public construction/operation on class C must produce a C instance
  //  - from_prompt(L2)+hint(L3): realized by routing every factory through cls/self
  //  - from_code(L6): one claim per documented input shape a..g and per op/ctor
  //  - frame(L4 / PO-2): instantiate C:=Permutation to recover identical legacy behavior

  // --- constructors (the 7 documented shapes a..g) -------------------------
  claim newP(C:Class, N:Int)        => obj(C, ?_:List) requires N >=Int 0   [all-path] // NEW-b (a,c,f analogous)
  claim newP(C:Class, A:List)       => obj(C, ?_:List)                      [all-path] // NEW-d/e (array/cyclic)
  claim newP(C:Class, obj(C, A:List)) => obj(C, A)                          [all-path] // NEW-g-id
  claim newP(C:Class, obj(D:Class, A:List)) => obj(C, A)
        requires notBool subq(D, C)                                         [all-path] // NEW-g-rebuild  [V2/B1]

  // --- operations on a C-instance ------------------------------------------
  claim inv(obj(C:Class, A:List))   => obj(C, invertA(A))                   [all-path] // OP-INV (~,**,^,mul_inv,…)
  claim obj(C:Class, A:List) * obj(D:Class, B:List) => obj(C, rmulA(A, B))  [all-path] // OP-MUL (left/self class)
  claim rmul(X:Int, obj(C:Class, A:List)) => obj(C, ?_:List)               [all-path] // OP-RMUL          [V2/B2]
  claim iunrank(obj(C:Class, A:List), N:Int) => obj(C, ?_:List)            [all-path] // OP-ADD/OP-NEXTNL [V2/B4,B5]

  // --- class-method constructors -------------------------------------------
  claim cctor(C:Class, N:Int)       => obj(C, ?_:List)                     [all-path] // CTOR-CLS
  claim josephus(C:Class, N:Int)    => obj(C, ?_:List)                     [all-path] // CTOR-JOS         [V1]
  claim fromseq(C:Class, I:List)    => obj(C, ?_:List)                     [all-path] // CTOR-FSEQ        [V2/B3]
endmodule
