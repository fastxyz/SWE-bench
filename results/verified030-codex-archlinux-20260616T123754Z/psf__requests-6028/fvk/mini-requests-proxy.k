module MINI-REQUESTS-PROXY-SYNTAX
  imports STRING-SYNTAX

  syntax PUrl ::= purl(String, String, String, String, String, String)
  syntax UrlOut ::= out(String, String, String, String, String)
  syntax KResult ::= UrlOut

  syntax KItem ::= prependScheme(PUrl, String)

  syntax String ::= effectiveScheme(String, String) [function]
                  | effectiveNetloc(String, String) [function]
                  | effectivePath(String, String) [function]
                  | withAuth(String, String) [function]
endmodule

module MINI-REQUESTS-PROXY
  imports MINI-REQUESTS-PROXY-SYNTAX
  imports STRING
  imports BOOL

  configuration <k> $PGM:K </k>

  rule effectiveScheme("", NEW:String) => NEW
  rule effectiveScheme(SCHEME:String, NEW:String) => SCHEME
    requires SCHEME =/=String ""

  rule effectiveNetloc("", PATH:String) => PATH
  rule effectiveNetloc(NETLOC:String, PATH:String) => NETLOC
    requires NETLOC =/=String ""

  rule effectivePath("", PATH:String) => ""
  rule effectivePath(NETLOC:String, PATH:String) => PATH
    requires NETLOC =/=String ""

  rule withAuth("", NETLOC:String) => NETLOC
  rule withAuth(AUTH:String, NETLOC:String) => AUTH +String "@" +String NETLOC
    requires AUTH =/=String ""

  rule
    <k>
      prependScheme(purl(SCHEME, AUTH, NETLOC, PATH, QUERY, FRAG), NEW)
      =>
      out(
        effectiveScheme(SCHEME, NEW),
        withAuth(AUTH, effectiveNetloc(NETLOC, PATH)),
        effectivePath(NETLOC, PATH),
        QUERY,
        FRAG
      )
    </k>
endmodule
