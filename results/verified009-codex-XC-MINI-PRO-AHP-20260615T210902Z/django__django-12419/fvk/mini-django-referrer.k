// Constructed FVK artifact, not machine-checked.
// Abstract semantics for the Django SECURE_REFERRER_POLICY default and the
// SecurityMiddleware Referrer-Policy response behavior.

module MINI-DJANGO-REFERRER-SYNTAX
  imports STRING-SYNTAX
  imports BOOL-SYNTAX
  imports MAP-SYNTAX

  syntax Policy ::= NonePolicy
                  | SameOrigin
                  | RawPolicy(String)

  syntax Command ::= defaultSECURE_REFERRER_POLICY
                   | defaultResponse(Map)
                   | processResponse(Policy, Map)

  syntax KResult ::= Policy | Map
endmodule

module MINI-DJANGO-REFERRER
  imports MINI-DJANGO-REFERRER-SYNTAX
  imports STRING
  imports BOOL
  imports MAP

  configuration <k> $PGM:Command </k>

  syntax String ::= render(Policy) [function]
  rule render(SameOrigin) => "same-origin"
  rule render(RawPolicy(S:String)) => S

  // Spec abstraction for HttpResponse.setdefault().
  syntax Bool ::= hasHeader(Map, String) [function]
  syntax Map ::= setDefaultHeader(Map, String, String) [function]
  rule setDefaultHeader(H:Map, K:String, V:String) => H
    requires hasHeader(H, K)
  rule setDefaultHeader(H:Map, K:String, V:String) => H [K <- V]
    requires notBool hasHeader(H, K)

  // V1 global default.
  rule <k> defaultSECURE_REFERRER_POLICY => SameOrigin ... </k>

  // A response processed by a middleware instance using the default setting.
  rule <k> defaultResponse(H:Map) => processResponse(SameOrigin, H) ... </k>

  // SecurityMiddleware.process_response() skips disabled policy values.
  rule <k> processResponse(NonePolicy, H:Map) => H ... </k>

  // SecurityMiddleware.process_response() delegates overwrite protection to
  // response.setdefault().
  rule <k> processResponse(P:Policy, H:Map) => setDefaultHeader(H, "Referrer-Policy", render(P)) ... </k>
    requires P =/=K NonePolicy
endmodule
