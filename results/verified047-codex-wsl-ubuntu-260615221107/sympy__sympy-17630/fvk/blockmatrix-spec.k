// Abstract K-style claims for BlockMatrix._blockmul.
// Constructed, not machine-checked in this benchmark session.

requires "mini-blockmatrix.k"

module BLOCKMATRIX-SPEC
  imports MINI-BLOCKMATRIX

  // SPEC-PROVENANCE:
  // - from_prompt: repeated block multiplication with ZeroMatrix blocks must not
  //   create scalar Zero blocks that lack .cols.
  // - from_docs: BlockMatrix is comprised of matrices.
  // - from_code: V2 normalizes scalar zero and is_ZeroMatrix entries using the
  //   output row and column block sizes.
  claim
    <k> entry(G:Grid, RS:Sizes, CS:Sizes, I:Int, J:Int)
      => zblock(sizeAt(RS, I), sizeAt(CS, J)) </k>
    requires isZeroLike(rawEntry(G, I, J))
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: non-zero matrix block expressions should remain the ordinary
  //   block product entries.
  // - from_code: V2 returns the raw block unchanged when it is not zero-like.
  claim
    <k> entry(G:Grid, RS:Sizes, CS:Sizes, I:Int, J:Int)
      => rawEntry(G, I, J) </k>
    requires notBool isZeroLike(rawEntry(G, I, J))
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: the first _blockmul result must be suitable for a second
  //   _blockmul call.
  // - from_contract: aligned block product row sizes come from the left operand
  //   and column sizes from the right operand.
  claim
    <k> blockmul(B1:BMat, B2:BMat)
      => normalize(rawMul(B1, B2), rowSizes(B1), colSizes(B2)) </k>
    requires validBMat(B1) andBool validBMat(B2) andBool aligned(B1, B2)
    [all-path]
endmodule
