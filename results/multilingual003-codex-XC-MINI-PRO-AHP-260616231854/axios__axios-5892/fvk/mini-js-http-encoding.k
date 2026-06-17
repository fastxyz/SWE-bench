module MINI-JS-HTTP-ENCODING-SYNTAX
  imports BOOL-SYNTAX
  imports INT-SYNTAX
  imports STRING-SYNTAX

  syntax Method ::= headMethod | otherMethod
  syntax Header ::= absent | present(String)
  syntax Decision ::= passThrough
                    | dropEncodingOnly
                    | unzipAndDropEncoding
                    | deflateAndDropEncoding
                    | brotliAndDropEncoding

  syntax Decision ::= decide(Bool, Method, Int, Header, Bool)
                    | dispatch(String, Bool)

  // Abstraction of JavaScript String(E || '').trim().toLowerCase().
  syntax String ::= norm(String) [function]

  syntax KResult ::= Decision
endmodule

module MINI-JS-HTTP-ENCODING
  imports MINI-JS-HTTP-ENCODING-SYNTAX
  imports BOOL
  imports INT
  imports STRING

  configuration <k> $PGM:Decision </k>

  rule <k> decide(false, M:Method, S:Int, H:Header, BR:Bool) => passThrough ... </k>
  rule <k> decide(true, M:Method, S:Int, absent, BR:Bool) => passThrough ... </k>
  rule <k> decide(true, headMethod, S:Int, present(E:String), BR:Bool) => dropEncodingOnly ... </k>
  rule <k> decide(true, otherMethod, 204, present(E:String), BR:Bool) => dropEncodingOnly ... </k>
  rule <k> decide(true, otherMethod, STATUS:Int, present(E:String), BR:Bool) => dispatch(norm(E), BR) ... </k>
    requires STATUS =/=Int 204

  rule <k> dispatch("gzip", BR:Bool) => unzipAndDropEncoding ... </k>
  rule <k> dispatch("x-gzip", BR:Bool) => unzipAndDropEncoding ... </k>
  rule <k> dispatch("compress", BR:Bool) => unzipAndDropEncoding ... </k>
  rule <k> dispatch("x-compress", BR:Bool) => unzipAndDropEncoding ... </k>
  rule <k> dispatch("deflate", BR:Bool) => deflateAndDropEncoding ... </k>
  rule <k> dispatch("br", true) => brotliAndDropEncoding ... </k>
  rule <k> dispatch("br", false) => passThrough ... </k>
  rule <k> dispatch(E:String, BR:Bool) => passThrough ... </k> [owise]
endmodule
