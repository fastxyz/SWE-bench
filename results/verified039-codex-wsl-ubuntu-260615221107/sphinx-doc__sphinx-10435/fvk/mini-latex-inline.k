module MINI-LATEX-INLINE-SYNTAX
  imports STRING-SYNTAX

  syntax FormatterOut ::= beginVerbatim(String)
  syntax InlineOut ::= sphinxRaw(String) | sphinxPct(String)
  syntax KItem ::= RenderInline(FormatterOut)
                 | RenderThenVisible(FormatterOut)
                 | TeXVisible(InlineOut)
  syntax KResult ::= String | InlineOut
endmodule

module MINI-LATEX-INLINE
  imports MINI-LATEX-INLINE-SYNTAX
  imports STRING

  configuration <k> $PGM:K </k>

  // V2/V1 behavior: formatter boundary newlines are protected by TeX comments.
  rule <k> RenderInline(beginVerbatim(Body:String)) => sphinxPct(Body) ... </k>
  rule <k> RenderThenVisible(beginVerbatim(Body:String))
        => TeXVisible(sphinxPct(Body)) ... </k>

  // TeX interpretation abstraction:
  // - sphinxRaw models the pre-fix wrapper with bare newlines in a macro argument.
  // - sphinxPct models the fixed wrapper with percent comments at those line ends.
  rule <k> TeXVisible(sphinxRaw(Body:String))
        => " " +String Body +String " " ... </k>
  rule <k> TeXVisible(sphinxPct(Body:String)) => Body ... </k>
endmodule
