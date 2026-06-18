requires "mini-blockmatrix.k"

module BLOCKMUL-SPEC
  imports MINI-BLOCKMATRIX

  // SPEC-PROVENANCE:
  // - from_prompt: "the zeros in b._blockmul(b) are not ZeroMatrix but Zero"
  //   => exact scalar zero in a block-product position must become shaped zero.
  // - from_code: V1 nested entry(i, j) returns ZeroMatrix(rowblocksizes[i],
  //   colblocksizes[j]) for non-matrix scalar 0.
  // CLAIM: NORMALIZE-SCALAR-ZERO
  claim
    <k> normalize(scalarZero, R:Int, C:Int) => zeroMatrix(R, C) ... </k>
    requires R >=Int 0 andBool C >=Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: one multiplication "seems to work fine" for nonzero a**2.
  // - from_code: V1 returns already-matrix product entries unchanged.
  // CLAIM: NORMALIZE-MATRIX-PRESERVE
  claim
    <k> normalize(MB:Block, R:Int, C:Int) => MB ... </k>
    requires R >=Int 0 andBool C >=Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: repeated multiplication fails because a raw scalar Zero
  //   block lacks .cols.
  // - from_docs_or_tests: BlockMatrix is comprised of matrix blocks.
  // - from_code: compatible branch is selected by matching block sizes.
  // CLAIM: BLOCKMUL-COMPATIBLE-ZERO-ENTRY
  claim
    <k> resultEntry(A:BM, B:BM, I:Int, J:Int)
      => zeroMatrix(rowSize(A, I), colSize(B, J)) ... </k>
    requires compatible(A, B)
     andBool 0 <=Int I andBool I <Int rowCount(A)
     andBool 0 <=Int J andBool J <Int colCount(B)
     andBool rawEntry(A, B, I, J) ==K scalarZero
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: only scalar zero blocks are defective.
  // - from_code: V1 leaves matrix blocks untouched.
  // CLAIM: BLOCKMUL-COMPATIBLE-MATRIX-ENTRY
  claim
    <k> resultEntry(A:BM, B:BM, I:Int, J:Int) => MB:Block ... </k>
    requires compatible(A, B)
     andBool 0 <=Int I andBool I <Int rowCount(A)
     andBool 0 <=Int J andBool J <Int colCount(B)
     andBool rawEntry(A, B, I, J) ==K MB
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: later multiplication reads result block dimensions.
  // - from_code: row block sizes for a product come from the left operand.
  // CLAIM: BLOCKMUL-RESULT-ROW-SHAPE
  claim
    <k> entryRows(product(A:BM, B:BM), I:Int, J:Int) => rowSize(A, I) ... </k>
    requires compatible(A, B)
     andBool 0 <=Int I andBool I <Int rowCount(A)
     andBool 0 <=Int J andBool J <Int colCount(B)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: later multiplication reads result block dimensions.
  // - from_code: column block sizes for a product come from the right operand.
  // CLAIM: BLOCKMUL-RESULT-COL-SHAPE
  claim
    <k> entryCols(product(A:BM, B:BM), I:Int, J:Int) => colSize(B, J) ... </k>
    requires compatible(A, B)
     andBool 0 <=Int I andBool I <Int rowCount(A)
     andBool 0 <=Int J andBool J <Int colCount(B)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: b._blockmul(b)._blockmul(b) should not fail with scalar
  //   Zero missing .rows/.cols.
  // - from_code: every compatible product entry passes through normalize.
  // CLAIM: BLOCKMUL-REPEATED-SAFE
  claim
    <k> isMatrixEntry(product(A:BM, B:BM), I:Int, J:Int) => true ... </k>
    requires compatible(A, B)
     andBool 0 <=Int I andBool I <Int rowCount(A)
     andBool 0 <=Int J andBool J <Int colCount(B)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_test: X._blockmul(M).is_MatMul for non-BlockMatrix M.
  // - from_code: V1 does not change the fallback return.
  // CLAIM: BLOCKMUL-NONBLOCK-FALLBACK
  claim
    <k> blockMul(A:BM, nonBlock(X:Id)) => fallback(A, nonBlock(X)) ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: incompatible BlockMatrix operands use the same fallback
  //   branch as before V1.
  // - from_default_domain: incompatible block shapes are outside the block
  //   product domain.
  // CLAIM: BLOCKMUL-INCOMPATIBLE-FALLBACK
  claim
    <k> blockMul(A:BM, block(B:BM)) => fallback(A, block(B)) ... </k>
    requires notBool compatible(A, B)
    [all-path]
endmodule
