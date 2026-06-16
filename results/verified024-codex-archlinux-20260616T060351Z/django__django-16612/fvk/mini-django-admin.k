module MINI-DJANGO-ADMIN-SYNTAX
  imports BOOL
  imports STRING

  syntax Decision ::= Redirect(String) | Http404
  syntax Action ::= CatchAll(Bool, Bool, Bool, Bool, String, String)
                  | GetFullPathSlash(String, String)

  syntax Bool ::= endsWithSlash(String) [function, total]
  syntax String ::= escapedPath(String) [function, total]
  syntax String ::= encodedQuery(String) [function, total]
  syntax String ::= slashPath(String) [function, total]
  syntax String ::= fullPathSlash(String, String) [function, total]
endmodule

module MINI-DJANGO-ADMIN
  imports MINI-DJANGO-ADMIN-SYNTAX
  imports BOOL
  imports STRING

  configuration <k> $PGM:Action </k>

  rule <k> CatchAll(true, false, true, true, PATH, QUERY)
        => Redirect(fullPathSlash(PATH, QUERY)) ... </k>

  rule <k> CatchAll(false, URLENDS, RESOLVES, SHOULD, PATH, QUERY)
        => Http404 ... </k>
  rule <k> CatchAll(true, true, RESOLVES, SHOULD, PATH, QUERY)
        => Http404 ... </k>
  rule <k> CatchAll(true, false, false, SHOULD, PATH, QUERY)
        => Http404 ... </k>
  rule <k> CatchAll(true, false, true, false, PATH, QUERY)
        => Http404 ... </k>

  rule <k> GetFullPathSlash(PATH, QUERY)
        => fullPathSlash(PATH, QUERY) ... </k>

  rule slashPath(PATH) => escapedPath(PATH) +String "/"
    requires notBool endsWithSlash(PATH)
  rule slashPath(PATH) => escapedPath(PATH)
    requires endsWithSlash(PATH)

  rule fullPathSlash(PATH, "") => slashPath(PATH)
  rule fullPathSlash(PATH, QUERY) => slashPath(PATH) +String "?" +String encodedQuery(QUERY)
    requires QUERY =/=String ""
endmodule
