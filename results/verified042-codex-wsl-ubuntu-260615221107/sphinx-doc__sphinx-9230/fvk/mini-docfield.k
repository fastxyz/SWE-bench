module MINI-DOCFIELD-SYNTAX
  imports STRING
  imports BOOL

  syntax Words ::= word(String)
                 | words(Words, String)

  syntax SplitResult ::= noInline(String)
                       | inline(String, String)

  syntax ScanResult ::= scanResult(Bool, Bool, String)

  syntax KItem ::= parseInline(Words)
                 | scanParam(Words)
endmodule

module MINI-DOCFIELD
  imports MINI-DOCFIELD-SYNTAX
  imports STRING
  imports BOOL

  configuration <k> $PGM:K </k>

  syntax String ::= joinWords(Words) [function]
  rule joinWords(word(S)) => S
  rule joinWords(words(WS, S)) => joinWords(WS) +String " " +String S

  // One token means there is no inline type expression.
  rule <k> parseInline(word(NAME)) => noInline(NAME) ... </k>

  // V1 behavior: split from the right.  The final token is the parameter name;
  // everything to its left remains the type expression.
  rule <k> parseInline(words(TYPE, NAME)) => inline(joinWords(TYPE), NAME) ... </k>

  // Autodoc type-hint scanner abstraction:
  //   scanResult(hasDescription, hasType, parameterName)
  rule <k> scanParam(word(NAME)) => scanResult(true, false, NAME) ... </k>
  rule <k> scanParam(words(TYPE, NAME)) => scanResult(true, true, NAME) ... </k>
endmodule
