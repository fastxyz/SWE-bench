module MINI-SPECTRAL-SYNTAX
  imports INT-SYNTAX
  imports LIST

  syntax Pgm ::= normalizePsdSpectrum(Int, List)
               | oldNormalizePsdSpectrum(Int, List)
               | normalizePsdDensity(Int, List, Int)

  syntax Spec ::= scaled(Int, Int)
  syntax KResult ::= Spec
endmodule

module MINI-SPECTRAL
  imports MINI-SPECTRAL-SYNTAX
  imports INT
  imports LIST

  configuration <k> $PGM:Pgm </k>

  syntax Int ::= absInt(Int) [function]
  rule absInt(I:Int) => I requires I >=Int 0
  rule absInt(I:Int) => 0 -Int I requires I <Int 0

  syntax Int ::= signedSum(List) [function]
  rule signedSum(.List) => 0
  rule signedSum(ListItem(I:Int) W:List) => I +Int signedSum(W)

  syntax Int ::= absCoeffSum(List) [function]
  rule absCoeffSum(.List) => 0
  rule absCoeffSum(ListItem(I:Int) W:List) => absInt(I) +Int absCoeffSum(W)

  syntax Int ::= powerNorm(List) [function]
  rule powerNorm(.List) => 0
  rule powerNorm(ListItem(I:Int) W:List) => (I *Int I) +Int powerNorm(W)

  rule <k> normalizePsdSpectrum(RAW:Int, W:List)
        => scaled(RAW, signedSum(W) *Int signedSum(W)) </k>

  rule <k> oldNormalizePsdSpectrum(RAW:Int, W:List)
        => scaled(RAW, absCoeffSum(W) *Int absCoeffSum(W)) </k>

  rule <k> normalizePsdDensity(RAW:Int, W:List, FS:Int)
        => scaled(RAW, FS *Int powerNorm(W)) </k>
endmodule

