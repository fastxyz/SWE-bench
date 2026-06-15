module MINI-FITS-IDENTIFIER-SYNTAX
  imports BOOL-SYNTAX

  syntax PathKind ::= noPath | fitsPath | nonFitsPath
  syntax FileKind ::= noFile | fitsSignatureFile | nonFitsSignatureFile
  syntax ArgKind ::= hduArg | nonHduArg
  syntax ArgsKind ::= noArgs | arg(ArgKind, ArgsKind)

  syntax Bool ::= isFits(PathKind, FileKind, ArgsKind) [function]
                | firstArgIsHdu(ArgsKind)              [function]
endmodule

module MINI-FITS-IDENTIFIER
  imports MINI-FITS-IDENTIFIER-SYNTAX
  imports BOOL

  configuration <k> $PGM:Bool </k>

  // File-object branch has priority over path and object fallback.
  rule isFits(P:PathKind, fitsSignatureFile, AS:ArgsKind) => true
  rule isFits(P:PathKind, nonFitsSignatureFile, AS:ArgsKind) => false

  // Path branch matches only known FITS suffixes; otherwise it falls through.
  rule isFits(fitsPath, noFile, AS:ArgsKind) => true
  rule isFits(nonFitsPath, noFile, AS:ArgsKind) => firstArgIsHdu(AS)
  rule isFits(noPath, noFile, AS:ArgsKind) => firstArgIsHdu(AS)

  // V1 fix: empty args is a non-match, not an attempt to inspect args[0].
  rule firstArgIsHdu(noArgs) => false
  rule firstArgIsHdu(arg(hduArg, REST:ArgsKind)) => true
  rule firstArgIsHdu(arg(nonHduArg, REST:ArgsKind)) => false
endmodule
