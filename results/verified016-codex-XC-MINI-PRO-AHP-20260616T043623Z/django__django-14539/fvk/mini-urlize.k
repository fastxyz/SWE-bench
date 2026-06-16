module MINI-URLIZE-SYNTAX
  imports STRING
  imports BOOL
  imports INT

  syntax Span ::= span(String, String)  [klabel(span)]
  syntax Spans ::= ".Spans" | Span Spans [klabel(_Spans)]
  syntax Result ::= result(Spans, Spans) [klabel(result)]

  syntax Bool ::= isTrailPunct(String)  [function]
                | allTrailPunct(String) [function]
  syntax String ::= unescape(String)    [function]
  syntax Int ::= lenDecoded(String)     [function]
  syntax Spans ::= trim(Spans)          [function]
  syntax String ::= concatSource(Spans) [function]
                | concatDecoded(Spans) [function]
endmodule

module MINI-URLIZE
  imports MINI-URLIZE-SYNTAX

  configuration <k> $PGM:K </k>

  // This is a focused source-span semantics for FVK reasoning, not full Python.
  // A span stores (source, decoded). Trimming removes the maximal trailing
  // sequence whose decoded text is trailing punctuation, preserving source
  // spans exactly.
endmodule
