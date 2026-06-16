requires "domains.md"

module MINI-DJANGO-VIEW-SYNTAX
  imports STRING

  syntax ViewKind ::= "syncView" | "asyncView"
  syntax HandlerKind ::= "missingHandler" | "syncHandler" | "asyncHandler"
  syntax Status ::= "ok" | "methodNotAllowed"
  syntax Response ::= "response" "(" Status "," String ")"
  syntax Result ::= "direct" "(" Response ")"
                  | "awaitable" "(" Response ")"
                  | "typeError" "(" String ")"
  syntax Method ::= "GET" | "POST" | "OPTIONS" | "OTHER"

  syntax Exp ::= "dispatch" "(" ViewKind "," Method "," HandlerKind "," String ")"
               | "httpMethodNotAllowed" "(" ViewKind "," String ")"
               | "options" "(" ViewKind "," String ")"
               | "await" "(" Result ")"
  syntax KResult ::= Result
endmodule

module MINI-DJANGO-VIEW
  imports MINI-DJANGO-VIEW-SYNTAX

  configuration <k> $PGM:K </k>

  rule <k> dispatch(VK, GET, missingHandler, Allowed)
        => httpMethodNotAllowed(VK, Allowed) ... </k>

  rule <k> dispatch(VK, POST, missingHandler, Allowed)
        => httpMethodNotAllowed(VK, Allowed) ... </k>

  rule <k> dispatch(VK, OTHER, missingHandler, Allowed)
        => httpMethodNotAllowed(VK, Allowed) ... </k>

  rule <k> dispatch(syncView, GET, syncHandler, Allowed)
        => direct(response(ok, Allowed)) ... </k>

  rule <k> dispatch(syncView, POST, syncHandler, Allowed)
        => direct(response(ok, Allowed)) ... </k>

  rule <k> dispatch(syncView, OTHER, syncHandler, Allowed)
        => direct(response(ok, Allowed)) ... </k>

  rule <k> dispatch(asyncView, GET, asyncHandler, Allowed)
        => awaitable(response(ok, Allowed)) ... </k>

  rule <k> dispatch(asyncView, POST, asyncHandler, Allowed)
        => awaitable(response(ok, Allowed)) ... </k>

  rule <k> dispatch(asyncView, OTHER, asyncHandler, Allowed)
        => awaitable(response(ok, Allowed)) ... </k>

  rule <k> dispatch(VK, OPTIONS, missingHandler, Allowed)
        => options(VK, Allowed) ... </k>

  rule <k> httpMethodNotAllowed(syncView, Allowed)
        => direct(response(methodNotAllowed, Allowed)) ... </k>

  rule <k> httpMethodNotAllowed(asyncView, Allowed)
        => awaitable(response(methodNotAllowed, Allowed)) ... </k>

  rule <k> options(syncView, Allowed)
        => direct(response(ok, Allowed)) ... </k>

  rule <k> options(asyncView, Allowed)
        => awaitable(response(ok, Allowed)) ... </k>

  rule <k> await(awaitable(R)) => direct(R) ... </k>

  // This rule models the pre-V1 failure shape for findings only: awaiting a
  // direct response is invalid. V1's async fallback avoids producing this state.
  rule <k> await(direct(R)) => typeError("object HttpResponseNotAllowed can't be used in await expression") ... </k>
endmodule
