// mini-matexpr.k — a minimal K fragment for sympy__sympy-17630
//
// CONSTRUCTED, NOT MACHINE-CHECKED (no K toolchain in this environment).
//
// Scope (mini-X stopgap): model ONLY the fragment of SymPy that the fix and the
// bug touch — just enough to state the contract and discharge it:
//
//   * the value domain of "matrix-expression entries" that flow through the
//     block-matrix machinery: a genuine matrix (carrying its shape) OR the
//     scalar S.Zero (which is NOT a matrix);
//   * mmul(_,_)         <-> MatMul(...).doit()              (with any_zeros)
//   * addM(_)           <-> the core  Add(*args)  constructor + the MatrixExpr
//                           "Add" constructor-postprocessor + MatAdd canonicalize
//                           (rm_id / unpack), in the *fixed* form;
//   * addMbug(_)        <-> the SAME path BEFORE the fix (prepends the scalar
//                           additive identity S.Zero, modeling cls._from_args([]));
//   * cols(_)/rows(_)   <-> the .cols / .rows attribute access used by
//                           BlockMatrix.colblocksizes / rowblocksizes;
//   * repZ / colsizes   <-> the two real loops (dense _eval_matrix_mul builds an
//                           entry as Add over a k-indexed list; colblocksizes maps
//                           .cols over a block row).
//
// Nothing else from SymPy is modeled (no full Add.flatten, no Basic, no real
// MatAdd rule set) — exactly the mini-X discipline.

module MINI-MATEXPR-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  // ----- matrix-expression VALUES -----
  // A value is either a genuine matrix (with its (rows, cols) shape) or the
  // scalar zero.  The whole bug is that an all-zero matrix sum could become s0.
  syntax MVal ::= "s0"                        // scalar S.Zero   (is_Matrix == False)
                | "Z"   "(" Int "," Int ")"   // ZeroMatrix(rows, cols)
                | "Sym" "(" Int "," Int ")"   // a generic NON-zero MatrixExpr(rows, cols)

  // a (comma-separated) list of values: the argument list of a sum / a block row
  syntax MVals ::= ".MVals"
                 | MVal "," MVals   [right]

  syntax KItem ::= MVal | MVals
  syntax KResult ::= MVal | Int | Bool
endmodule


module MINI-MATEXPR
  imports MINI-MATEXPR-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:KItem </k>

  // ===================================================================
  // 1. MatMul.doit()  — only the any_zeros + shape behavior we need
  //    mmul(X, Y) with cols(X) == rows(Y); a zero factor makes the
  //    product a ZeroMatrix of the outer shape (this is matmul.any_zeros).
  // ===================================================================
  syntax MVal ::= mmul(MVal, MVal)            [function]
  rule mmul(Sym(P, K), Sym(K, Q)) => Sym(P, Q)
  rule mmul(Z(P, K),   Sym(K, Q)) => Z(P, Q)
  rule mmul(Sym(P, K), Z(K, Q))   => Z(P, Q)
  rule mmul(Z(P, K),   Z(K, Q))   => Z(P, Q)

  // ===================================================================
  // 2. The .cols / .rows attribute access (BlockMatrix.colblocksizes).
  //    DEFINED for matrices; DELIBERATELY UNDEFINED for s0 — there is no
  //    rule for cols(s0), so the term is STUCK.  That stuck state is the
  //    faithful model of:  AttributeError: 'Zero' object has no attribute 'cols'
  // ===================================================================
  syntax Int ::= cols(MVal) [function]
  syntax Int ::= rows(MVal) [function]
  rule cols(Z(_, Q))   => Q
  rule cols(Sym(_, Q)) => Q
  rule rows(Z(P, _))   => P
  rule rows(Sym(P, _)) => P
  // (no rule for cols(s0) / rows(s0): a scalar has no shape -> stuck)

  // ===================================================================
  // 3. Helpers over value lists (these are the recursive "loops").
  // ===================================================================

  // is this term an additive identity that MatAdd's rm_id removes?
  //   rm_id(lambda x: x == 0 or isinstance(x, ZeroMatrix))
  syntax Bool ::= isZeroLike(MVal) [function]
  rule isZeroLike(s0)       => true       // scalar 0   (x == 0)
  rule isZeroLike(Z(_, _))  => true       // ZeroMatrix (isinstance ZeroMatrix)
  rule isZeroLike(Sym(_,_)) => false

  // allZeroLike: every element is an identity  (RECURSION #1)
  syntax Bool ::= allZeroLike(MVals) [function]
  rule allZeroLike(.MVals)   => true
  rule allZeroLike(M, REST)  => isZeroLike(M) andBool allZeroLike(REST)

  // headList: the singleton [head]  (rm_id "if only identities then keep one")
  syntax MVals ::= headList(MVals) [function]
  rule headList(M, _:MVals) => M, .MVals

  // nonZeros: keep only the non-identity terms  (rm_id, the common branch) (RECURSION #2)
  syntax MVals ::= nonZeros(MVals) [function]
  rule nonZeros(.MVals)  => .MVals
  rule nonZeros(M, REST) => M, nonZeros(REST)  requires notBool isZeroLike(M)
  rule nonZeros(M, REST) =>    nonZeros(REST)  requires isZeroLike(M)

  // ===================================================================
  // 4. MatAdd canonicalize (the rules that matter): rm_id then unpack.
  // ===================================================================
  //   rm_id: all-identities -> keep the head; otherwise -> drop identities
  syntax MVals ::= rmId(MVals) [function]
  rule rmId(M, REST) => headList(M, REST)
       requires allZeroLike(M, REST)
  rule rmId(M, REST) => nonZeros(M, REST)
       requires notBool allZeroLike(M, REST)

  //   unpack: a singleton collapses to its element; >= 2 stays a (matrix) sum.
  //   A non-empty sum of same-shape terms is itself a matrix of that shape;
  //   we model it as Sym(P, Q) using the head's shape (it is non-zero here).
  syntax MVal ::= canon(MVals) [function]
  rule canon(M, .MVals)            => M
  rule canon(Sym(P, Q), (_, _))    => Sym(P, Q)     // >=2 terms, head non-zero
  rule canon(Z(P, Q),  (_, _))     => Z(P, Q)       // (only reached if a non-id slipped past rm_id; shape kept)

  // ===================================================================
  // 5. The core Add(*matrices) over all-matrix args, via the postprocessor.
  // ===================================================================
  // FIXED form  (matexpr.get_postprocessor, the V1/V2 fix):
  //   nonmatrices is empty and mat_class is MatAdd  =>  MatAdd(*matrices).doit()
  //   i.e. NO scalar identity is prepended.
  syntax MVal ::= addM(MVals) [function]
  rule addM(L) => canon(rmId(L))

  // BUGGY form (base commit): the postprocessor reached
  //   mat_class(cls._from_args([]), *matrices).doit()  ==  MatAdd(S.Zero, *matrices).doit()
  // i.e. it PREPENDED the scalar identity S.Zero (modeled as s0).
  syntax MVal ::= addMbug(MVals) [function]
  rule addMbug(L) => canon(rmId(s0, L))

  // ===================================================================
  // 6. The two real loops, as recursive list builders/mappers.
  // ===================================================================
  // repZ(P, Q, K): the k-indexed argument list of a single product entry when
  // every product is a zero block — i.e. dense _eval_matrix_mul's `vec`.
  syntax MVals ::= repZ(Int, Int, Int) [function]
  rule repZ(P, Q, K) => Z(P, Q), repZ(P, Q, K -Int 1)  requires K >=Int 1
  rule repZ(P, Q, 0) => .MVals

  // colsizes(L): BlockMatrix.colblocksizes mapping .cols over a block row.
  syntax IntList ::= ".IntList" | Int "," IntList [right]
  syntax KItem   ::= IntList
  syntax KResult ::= IntList
  syntax IntList ::= colsizes(MVals) [function]
  rule colsizes(.MVals)  => .IntList
  rule colsizes(M, REST) => cols(M), colsizes(REST)
endmodule
