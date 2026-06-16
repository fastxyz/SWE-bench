requires "domains.md"

module MINI-PYTHON-REQUESTS-URL-SYNTAX
  imports STRING-SYNTAX

  syntax Result ::= validHost(String)
                  | invalidURL(String)

  syntax KItem ::= prepareAsciiHost(String)
endmodule

module MINI-PYTHON-REQUESTS-URL
  imports MINI-PYTHON-REQUESTS-URL-SYNTAX
  imports BOOL
  imports INT
  imports STRING

  configuration <k> $PGM:K </k>

  syntax Bool ::= StartsWith(String, String) [function]
                | Contains(String, String) [function]
                | BadAsciiHost(String) [function]

  rule StartsWith(S, Prefix)
    => lengthString(S) >=Int lengthString(Prefix)
       andBool substrString(S, 0, lengthString(Prefix)) ==String Prefix

  rule Contains(S, Needle)
    => findString(S, Needle, 0) =/=Int -1

  rule BadAsciiHost(H)
    => StartsWith(H, "*") orBool StartsWith(H, ".") orBool Contains(H, "..")

  rule <k> prepareAsciiHost(H) => invalidURL("URL has an invalid label.") ... </k>
    requires BadAsciiHost(H)

  rule <k> prepareAsciiHost(H) => validHost(H) ... </k>
    requires notBool BadAsciiHost(H)
endmodule
