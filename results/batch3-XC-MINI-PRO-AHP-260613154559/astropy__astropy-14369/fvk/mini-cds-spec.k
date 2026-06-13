// mini-cds-spec.k — reachability claims for the CDS division-chain reduction.
// "constructed, not machine-checked."
//
// Run-commands (expected output #Top = all claims proved):
//   kompile mini-cds.k --backend haskell
//   kprove  mini-cds-spec.k

requires "mini-cds.k"

module MINI-CDS-SPEC-SYNTAX
  imports MINI-CDS-SYNTAX
endmodule

module VERIFICATION
  imports MINI-CDS-SPEC-SYNTAX
  imports MINI-CDS
  imports INT
endmodule

module MINI-CDS-SPEC
  imports VERIFICATION

  // (DIVCHAIN) — the contract the V1 fix must satisfy.
  //   For every leading unit A, denominator sequence L, and generator I, the V1
  //   left fold puts EVERY operand of L in the denominator:
  //       expo(pdiv(A, L), I)  =  expo(A, I) - Σ_{x in L} expo(x, I)
  //   i.e.  u0/u1/.../un  ==  u0 / (u1 * u2 * ... * un).
  //   No precondition: it holds for all A, L, I  (a clean, total spec).
  //   Proved by induction on L (this claim is its own circularity); VCs are linear.
  claim expo(pdiv(A:Unit, L:UnitList), I:Int)
     => expo(A, I) -Int sumExpo(L, I)
     [all-path]

  // Leading division  /u1/.../un  is the special case A = one:
  //   pdiv(one, L)  ==  1 / (u1*...*un).   Subsumed by (DIVCHAIN) at A = one.
  claim expo(pdiv(one, L:UnitList), I:Int)
     => 0 -Int sumExpo(L, I)
     [all-path]

  // (BUG-V0) — the OLD right fold is wrong on a 2-element chain: it ADDS the last
  //   operand's exponent instead of subtracting it.  This claim is what V0 actually
  //   computes; contrast it with (DIVCHAIN), which gives  ... -Int expo(X2,I).
  //   The two differ by  2 *Int expo(X2,I)  (= 2 for X2 a base unit gen(k)).
  claim expo(pdivR(A:Unit, (X1:Unit : (X2:Unit : .UnitList))), I:Int)
     => (expo(A,I) -Int expo(X1,I)) +Int expo(X2,I)
     [all-path]
endmodule
