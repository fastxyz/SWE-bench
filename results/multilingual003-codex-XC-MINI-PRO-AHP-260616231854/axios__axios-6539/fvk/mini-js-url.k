module MINI-JS-URL-SYNTAX
  imports BOOL-SYNTAX

  syntax C ::= "c0" | "slash" | "backslash" | "other"
  syntax URL ::= ".URL" | C URL
  syntax Outcome ::= "rejectInvalid" | "parseWithFallback"
  syntax Exp ::= "isProtocolRelativeURL" "(" URL ")"
               | "prepare" "(" URL ")"
  syntax KItem ::= "decide" "(" URL ")"
  syntax KResult ::= Bool | Outcome
endmodule

module MINI-JS-URL
  imports MINI-JS-URL-SYNTAX
  imports BOOL

  configuration <k> $PGM:Exp </k>

  rule <k> isProtocolRelativeURL(c0 U:URL) => isProtocolRelativeURL(U) ... </k>
  rule <k> isProtocolRelativeURL(slash slash U:URL) => true ... </k>
  rule <k> isProtocolRelativeURL(slash backslash U:URL) => true ... </k>
  rule <k> isProtocolRelativeURL(backslash slash U:URL) => true ... </k>
  rule <k> isProtocolRelativeURL(backslash backslash U:URL) => true ... </k>
  rule <k> isProtocolRelativeURL(slash other U:URL) => false ... </k>
  rule <k> isProtocolRelativeURL(backslash other U:URL) => false ... </k>
  rule <k> isProtocolRelativeURL(other U:URL) => false ... </k>
  rule <k> isProtocolRelativeURL(.URL) => false ... </k>

  rule <k> prepare(U:URL) => isProtocolRelativeURL(U) ~> decide(U) ... </k>
  rule <k> true ~> decide(U:URL) => rejectInvalid ... </k>
  rule <k> false ~> decide(U:URL) => parseWithFallback ... </k>
endmodule

