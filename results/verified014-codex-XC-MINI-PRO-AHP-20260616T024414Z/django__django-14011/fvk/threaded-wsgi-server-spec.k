requires "mini-close-request.k"

module THREADED-WSGI-SERVER-SPEC
  imports MINI-CLOSE-REQUEST

  // CLAIM C1: normal request-thread cleanup.
  // SPEC-PROVENANCE:
  // - from_prompt: "ThreadingMixIn creates a new thread for each request, but those threads don't close their database connections at their conclusion" => every request worker must close its own thread-local DB connections before completion.
  // - from_prompt: "database connections could perhaps be closed inside close_request()" => the cleanup hook is close_request().
  // - from_code: django.db.utils.ConnectionHandler.close_all() closes connections from the current thread-local connection storage.
  // - from_compatibility: socketserver.TCPServer.close_request() calls request.close(), so the override must still perform superclass cleanup.
  claim
    <k> close_request => .K ... </k>
    <dbOpen> N:Int => 0 </dbOpen>
    <requestClosed> false => true </requestClosed>
    <closeAllOutcome> normal </closeAllOutcome>
    <exception> false </exception>
    requires N >=Int 0
    [all-path]

  // CLAIM C2: inherited request cleanup is preserved even if DB cleanup raises.
  // SPEC-PROVENANCE:
  // - from_prompt: "close_request() ... Called to clean up an individual request" => overriding close_request must not skip the inherited request cleanup.
  // - from_code: V2 uses try/finally around connections.close_all() and super().close_request(request).
  // - proof-finding F2: V1 did not guarantee superclass cleanup if close_all() raised.
  claim
    <k> close_request => .K ... </k>
    <dbOpen> N:Int => ?M:Int </dbOpen>
    <requestClosed> false => true </requestClosed>
    <closeAllOutcome> dbError </closeAllOutcome>
    <exception> false => true </exception>
    requires N >=Int 0
    [all-path]
endmodule
