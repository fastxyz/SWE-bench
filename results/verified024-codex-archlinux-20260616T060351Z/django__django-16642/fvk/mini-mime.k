module MINI-MIME-SYNTAX
  syntax CType ::= textHtml | appOctet | appXBrotli | appXBzip
                 | appXCompress | appGzip | appXXz | videoWebm
  syntax MaybeCType ::= noType | some(CType)
  syntax Encoding ::= br | bzip2 | compress | gzip | xz | noEncoding
  syntax NonEmptyFileName ::= htmlBr | htmlZ | tarGz | tarBz2 | tarXz
                            | unknownFile | anyFile
  syntax FileName ::= noFile | file(NonEmptyFileName)
  syntax Explicit ::= noExplicit | explicit(CType)
  syntax Guess ::= noGuess | guess(MaybeCType, Encoding)
  syntax EncodingHeader ::= contentEncodingSet | noContentEncoding
  syntax KResult ::= CType | EncodingHeader

  syntax Exp ::= effectiveContentType(Explicit, FileName, Guess)
               | fromGuess(MaybeCType, Encoding)
               | compressedOrGuessed(CType, Encoding)
               | fileResponseSetsContentEncoding(Explicit, Guess)
endmodule

module MINI-MIME
  imports MINI-MIME-SYNTAX

  configuration <k> $PGM:Exp </k>

  rule <k> effectiveContentType(explicit(CT), FN, G) => CT ... </k>
  rule <k> effectiveContentType(noExplicit, noFile, G) => appOctet ... </k>
  rule <k> effectiveContentType(noExplicit, file(FN), guess(CT, ENC))
        => fromGuess(CT, ENC) ... </k>
  rule <k> effectiveContentType(noExplicit, file(FN), noGuess) => appOctet ... </k>

  rule <k> fromGuess(noType, ENC) => compressedOrGuessed(appOctet, ENC) ... </k>
  rule <k> fromGuess(some(CT), ENC) => compressedOrGuessed(CT, ENC) ... </k>

  rule <k> compressedOrGuessed(CT, br) => appXBrotli ... </k>
  rule <k> compressedOrGuessed(CT, bzip2) => appXBzip ... </k>
  rule <k> compressedOrGuessed(CT, compress) => appXCompress ... </k>
  rule <k> compressedOrGuessed(CT, gzip) => appGzip ... </k>
  rule <k> compressedOrGuessed(CT, xz) => appXXz ... </k>
  rule <k> compressedOrGuessed(CT, noEncoding) => CT ... </k>

  rule <k> fileResponseSetsContentEncoding(EX, G) => noContentEncoding ... </k>
endmodule
