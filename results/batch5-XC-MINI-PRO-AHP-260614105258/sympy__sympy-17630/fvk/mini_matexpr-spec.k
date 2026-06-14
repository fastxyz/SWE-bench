// mini-matexpr-spec.k — reachability claims for sympy__sympy-17630
//
// CONSTRUCTED, NOT MACHINE-CHECKED.  Proof write-up: fvk/PROOF.md.
//
// These claims pin the contract that the V1/V2 fix must satisfy, and a
// counter-claim that documents the bug as a STUCK state.

requires "mini_matexpr.k"

module MINI-MATEXPR-SPEC-SYNTAX
  imports MINI-MATEXPR-SYNTAX
endmodule

module VERIFICATION
  imports MINI-MATEXPR-SPEC-SYNTAX
  imports MINI-MATEXPR
endmodule

module MINI-MATEXPR-SPEC
  imports VERIFICATION

  // ---------------------------------------------------------------
  // (REPZ)  the argument-list builder is well-formed: an all-zero
  //         entry list is all-zero-like.  RECURSION/circularity on K.
  // SPEC-PROVENANCE:
  // - from_code: dense.py:198  new_mat[i] = Add(*vec)  where every product
  //   mmul(A[i,k],B[k,j]) is a ZeroMatrix for an all-zero entry.
  claim <k> allZeroLike(repZ(P:Int, Q:Int, K:Int)) => true </k>
    requires K >=Int 0
    [all-path]

  // ---------------------------------------------------------------
  // (ADD0)  THE function contract that the fix establishes:
  //         a non-empty sum of equal-shape ZeroMatrices is a ZeroMatrix
  //         of that shape — a MATRIX, never the scalar s0.
  // SPEC-PROVENANCE:
  // - from_prompt: "the zeros in b._blockmul(b) are not ZeroMatrix but Zero"
  //   => Add over zero blocks MUST stay a (zero) matrix.
  // - from_tests: test_matexpr.py:105,128,238 — matrix sums that vanish are
  //   ZeroMatrix(...), not S.Zero.
  // - from_code: matexpr.get_postprocessor (fixed): nonmatrices empty &
  //   mat_class==MatAdd => MatAdd(*matrices).doit() (no scalar 0 prepended).
  claim <k> addM(repZ(P:Int, Q:Int, K:Int)) => Z(P, Q) </k>
    requires K >=Int 1
    [all-path]

  // ---------------------------------------------------------------
  // (COLS-OK)  REPEATABILITY: .cols of such a block is DEFINED, so a second
  //            BlockMatrix._blockmul (which reads colblocksizes) cannot raise.
  // SPEC-PROVENANCE:
  // - from_prompt: "block-multiplying twice throws ... 'Zero' object has no
  //   attribute 'cols'"  => after the fix, cols(...) must reduce to an Int.
  claim <k> cols(addM(repZ(P:Int, Q:Int, K:Int))) => Q </k>
    requires K >=Int 1
    [all-path]

  // ---------------------------------------------------------------
  // (COLSIZES-OK)  the whole colblocksizes loop over a row of such blocks
  //                terminates with a list of Ints (no stuck/AttributeError).
  claim <k> colsizes(addM(repZ(P:Int, Q:Int, K:Int)), .MVals)
              => Q, .IntList </k>
    requires K >=Int 1
    [all-path]

  // ---------------------------------------------------------------
  // (BUG)  COUNTER-CLAIM, EXPECTED TO *FAIL* on the base (pre-fix) code.
  //        With the buggy postprocessor, the same block is the scalar s0,
  //        and cols(s0) has NO rule -> the proof gets STUCK at cols(s0).
  //        kprove would NOT return #Top here; the residual goal cols(s0)=>Q
  //        is exactly the AttributeError, surfaced as a proof obstacle.
  //        (Kept here only as documentation of the bug; not part of the
  //         positive correctness package.)
  claim <k> cols(addMbug(repZ(P:Int, Q:Int, K:Int))) => Q </k>
    requires K >=Int 1
    [all-path]
endmodule
