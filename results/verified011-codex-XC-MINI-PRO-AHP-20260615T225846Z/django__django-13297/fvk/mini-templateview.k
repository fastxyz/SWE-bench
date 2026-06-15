module MINI-TEMPLATEVIEW-SYNTAX
  imports ID-SYNTAX
  imports MAP

  syntax Val ::= raw(Id) | lazy(Id, Val) | obj(Id)
  syntax Cmd ::= get(Map, Map) | wrap(Map, Map) | render(Map)
endmodule

module MINI-TEMPLATEVIEW
  imports MINI-TEMPLATEVIEW-SYNTAX
  imports BOOL
  imports MAP

  configuration
    <k> $PGM:Cmd </k>
    <seenKwargs> .Map </seenKwargs>
    <response> .Map </response>

  syntax Map ::= wrapCtx(Map, Map) [function]

  rule wrapCtx(C:Map, .Map) => C
  rule wrapCtx(C:Map, (K:Id |-> V:Val) REST:Map)
    => wrapCtx(C [ K <- lazy(K, V) ], REST)
    requires K in_keys(C) andBool C [ K ] ==K V
  rule wrapCtx(C:Map, (K:Id |-> V:Val) REST:Map)
    => wrapCtx(C, REST)
    requires notBool (K in_keys(C) andBool C [ K ] ==K V)

  rule <k> get(KW:Map, C:Map) => wrap(C, KW) ... </k>
       <seenKwargs> _ => KW </seenKwargs>

  rule <k> wrap(C:Map, KW:Map) => render(wrapCtx(C, KW)) ... </k>

  rule <k> render(C:Map) => .K </k>
       <response> _ => C </response>
endmodule
