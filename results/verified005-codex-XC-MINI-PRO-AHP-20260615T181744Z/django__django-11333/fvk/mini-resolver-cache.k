// Constructed, not machine-checked. This is a small K model of the cache
// behavior relevant to django.urls.resolvers.get_resolver().

module MINI-RESOLVER-CACHE-SYNTAX
  imports INT-SYNTAX
  imports ID-SYNTAX

  syntax UrlConf ::= "NoUrlConf"
                   | "OmittedUrlConf"
                   | "url" "(" Id ")"

  syntax Cmd ::= "getResolver" "(" UrlConf ")"
               | "clearResolverCache"

  syntax KResult ::= Int
endmodule

module MINI-RESOLVER-CACHE
  imports MINI-RESOLVER-CACHE-SYNTAX
  imports INT
  imports BOOL
  imports MAP

  configuration
    <k> $PGM:K </k>
    <root> root:Id </root>
    <cache> .Map </cache>
    <next> 1 </next>
    <result> 0 </result>

  syntax Id ::= norm(UrlConf, Id) [function]
  rule norm(NoUrlConf, R:Id) => R
  rule norm(OmittedUrlConf, R:Id) => R
  rule norm(url(U:Id), R:Id) => U

  rule
    <k> getResolver(U:UrlConf) => .K ... </k>
    <root> R:Id </root>
    <cache> ... norm(U, R) |-> I:Int ... </cache>
    <result> _ => I </result>

  rule
    <k> getResolver(U:UrlConf) => .K ... </k>
    <root> R:Id </root>
    <cache> C:Map => C [ norm(U, R) <- I ] </cache>
    <next> I:Int => I +Int 1 </next>
    <result> _ => I </result>
    requires notBool (norm(U, R) in_keys(C))

  rule
    <k> clearResolverCache => .K ... </k>
    <cache> _ => .Map </cache>
endmodule
