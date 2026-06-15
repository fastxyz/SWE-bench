module MINI-PYTHON-MIDDLEWARE-SYNTAX
  imports BOOL-SYNTAX

  syntax Cmd ::= "mixinInit" "(" Bool ")"
               | "securityInit" "(" Bool ")"
               | "updateCacheInit" "(" Bool ")"
               | "fetchCacheInit" "(" Bool ")"
               | "combinedCacheInit" "(" Bool ")"
               | "setSecurity"
               | "setCache"
               | "setCombinedCacheOptions"

  // obj(getResponseIsAsync, recognizedAsync, securityAttrsSet,
  //     cacheAttrsSet, combinedCacheOptionsPreserved)
  syntax Obj ::= "obj" "(" Bool "," Bool "," Bool "," Bool "," Bool ")"
  syntax KResult ::= Bool | Obj
endmodule

module MINI-PYTHON-MIDDLEWARE
  imports MINI-PYTHON-MIDDLEWARE-SYNTAX
  imports BOOL

  configuration
    <k> $PGM:Cmd </k>
    <obj> obj(false, false, false, false, false) </obj>

  // Abstract MiddlewareMixin.__init__(): store get_response and make
  // asyncio.iscoroutinefunction(instance) agree with the wrapped handler.
  rule <k> mixinInit(B:Bool) => .K ... </k>
       <obj> obj(_:Bool, _:Bool, S:Bool, C:Bool, O:Bool)
          => obj(B, B, S, C, O)
       </obj>

  rule <k> securityInit(B:Bool) => mixinInit(B) ~> setSecurity ... </k>
  rule <k> updateCacheInit(B:Bool) => mixinInit(B) ~> setCache ... </k>
  rule <k> fetchCacheInit(B:Bool) => mixinInit(B) ~> setCache ... </k>
  rule <k> combinedCacheInit(B:Bool) => mixinInit(B) ~> setCombinedCacheOptions ... </k>

  rule <k> setSecurity => .K ... </k>
       <obj> obj(G:Bool, M:Bool, _:Bool, C:Bool, O:Bool)
          => obj(G, M, true, C, O)
       </obj>

  rule <k> setCache => .K ... </k>
       <obj> obj(G:Bool, M:Bool, S:Bool, _:Bool, O:Bool)
          => obj(G, M, S, true, O)
       </obj>

  // The combined cache middleware skips the cache parent constructors and
  // applies its own keyword-option handling after the mixin initialization.
  rule <k> setCombinedCacheOptions => .K ... </k>
       <obj> obj(G:Bool, M:Bool, S:Bool, _:Bool, _:Bool)
          => obj(G, M, S, true, true)
       </obj>
endmodule
