// Abstract mini-K model for the BlockMatrix._blockmul zero-normalization proof.
// Constructed, not machine-checked in this benchmark session.

module MINI-BLOCKMATRIX-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports ID-SYNTAX

  syntax Sizes
  syntax Grid
  syntax Block ::= mblock(Int, Int, Id)
                 | zblock(Int, Int)
                 | scalarZero
                 | genericZero

  syntax BMat ::= bmat(Sizes, Sizes, Grid)
  syntax KResult ::= BMat | Block | Grid | Sizes | Bool | Int

  syntax Exp ::= blockmul(BMat, BMat)
               | normalize(Grid, Sizes, Sizes)
               | entry(Grid, Sizes, Sizes, Int, Int)
endmodule

module MINI-BLOCKMATRIX
  imports MINI-BLOCKMATRIX-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:Exp </k>

  // Spec-only functions for the abstract model.
  syntax Int ::= len(Sizes) [function]
  syntax Int ::= sizeAt(Sizes, Int) [function]
  syntax Sizes ::= rowSizes(BMat) [function]
  syntax Sizes ::= colSizes(BMat) [function]
  syntax Grid ::= rawMul(BMat, BMat) [function]
  syntax Block ::= rawEntry(Grid, Int, Int) [function]
  syntax Grid ::= normalized(Grid, Sizes, Sizes) [function]
  syntax Bool ::= aligned(BMat, BMat) [function]
  syntax Bool ::= isZeroLike(Block) [function]
  syntax Bool ::= validBMat(BMat) [function]

  rule isZeroLike(scalarZero) => true
  rule isZeroLike(genericZero) => true
  rule isZeroLike(zblock(R:Int, C:Int)) => true
  rule isZeroLike(mblock(R:Int, C:Int, Name:Id)) => false

  rule <k> blockmul(B1:BMat, B2:BMat) => normalize(rawMul(B1, B2), rowSizes(B1), colSizes(B2)) </k>
    requires validBMat(B1) andBool validBMat(B2) andBool aligned(B1, B2)

  rule <k> normalize(G:Grid, RS:Sizes, CS:Sizes) => normalized(G, RS, CS) </k>

  rule <k> entry(G:Grid, RS:Sizes, CS:Sizes, I:Int, J:Int) => zblock(sizeAt(RS, I), sizeAt(CS, J)) </k>
    requires isZeroLike(rawEntry(G, I, J))

  rule <k> entry(G:Grid, RS:Sizes, CS:Sizes, I:Int, J:Int) => rawEntry(G, I, J) </k>
    requires notBool isZeroLike(rawEntry(G, I, J))
endmodule
