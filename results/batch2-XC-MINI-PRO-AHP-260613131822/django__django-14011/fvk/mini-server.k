// mini-server.k — a minimal K fragment modeling ONE worker thread's lifecycle
// in Django's ThreadedWSGIServer (socketserver.ThreadingMixIn), as changed by the
// V1 fix in django/core/servers/basehttp.py.
//
// SCOPE / "mini-X" stopgap (per fvk_materials/commands/formalize.md step 3):
// we model only the constructs the fixed code actually exercises *inside a single
// per-request worker thread*:
//
//   process_request_thread(self, request, client_address):
//       if self.connections_override:                # setOverride
//           for alias, conn in ...: connections[alias] = conn
//       super().process_request_thread(...)          # finish_request (handleRequest)
//                                                    #   ... finally shutdown_request
//                                                    #         -> close_request
//                                                    #              -> _close_connections()  (closeAll)
//
// The thread-local object `connections` (asgiref.local.Local, see
// django/utils/connection.py) is modeled as the per-thread cell <own>: the list of
// DatabaseWrapper "connections" this worker thread holds. Each connection is in one
// of three abstract states:
//
//   openShared  -- an OPEN connection that is thread-shared (in-memory SQLite, with
//                  inc_thread_sharing() already called by setUpClass). Its close()
//                  is a NO-OP (django/db/backends/sqlite3/base.py:270 skips the real
//                  close for is_in_memory_db()), so closing it leaves it openShared.
//   openLocal   -- an OPEN connection created lazily by this worker thread for a
//                  non-shared DB (postgres/mysql/file-sqlite). close() really closes.
//   closed      -- a closed connection.
//
// NOT modeled here (deliberate ESCALATION BOUNDARY, see FINDINGS F5 / PROOF.md):
//   * interleaving of *multiple* concurrent worker threads;
//   * the socket request object and super().close_request() (orthogonal resource);
//   * the real SQL/transaction semantics of a connection.
// These do not affect the per-thread cleanup invariant the fix establishes.

module MINI-SERVER-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports LIST

  // Abstract connection state.
  syntax ConnState ::= "openShared" | "openLocal" | "closed"

  // The worker-thread lifecycle is a sequence of three statements.
  syntax Stmt ::= "setOverride"            // copy connections_override into this thread
                | "handleRequest"          // finish_request: lazily open non-shared conns
                | "closeAll"               // _close_connections(): connections.close_all()
                > Stmt ";" Stmt   [left]   // sequencing binds loosest

  syntax KResult ::= Int | Bool
endmodule

module MINI-SERVER
  imports MINI-SERVER-SYNTAX
  imports INT
  imports BOOL
  imports LIST

  configuration
    <k> $PGM:Stmt </k>
    // <own>: this worker thread's thread-local `connections` (the asgiref Local view).
    <own>      .List         </own>
    // <override>: connections_override -- the shared in-memory conns from the main
    // thread. Each entry is openShared (open + inc_thread_sharing()).
    <override> $OVERRIDE:List </override>
    // <accesses>: how many *distinct non-shared* DBs the request touches (postgres,
    // etc.). finish_request lazily opens one openLocal per such DB.
    <accesses> $ACCESSES:Int  </accesses>

  // ---- close(): the abstract DatabaseWrapper.close() ----------------------------
  // openShared -> openShared  (in-memory: BaseDatabaseWrapper.close is skipped)
  // openLocal  -> closed      (real close)
  // closed     -> closed      (idempotent: connection is None -> early return)
  syntax ConnState ::= close ( ConnState ) [function, total]
  rule close(openShared) => openShared
  rule close(openLocal)  => closed
  rule close(closed)     => closed

  // closeList: map close over a list (spec vocabulary; the closed form of closeAll)
  syntax List ::= closeList ( List ) [function, total]
  rule closeList(.List)            => .List
  rule closeList(ListItem(S:ConnState) REST:List)
                                   => ListItem(close(S)) closeList(REST)

  // ---- setOverride --------------------------------------------------------------
  // `if self.connections_override: for alias,conn in ...: connections[alias]=conn`
  // Appends every shared connection to this thread's <own>, BEFORE the request runs.
  rule <k> setOverride => .K ... </k>
       <own> OWN:List => OWN OV </own>
       <override> OV:List </override>

  // ---- handleRequest ------------------------------------------------------------
  // finish_request handles the request; per distinct non-shared DB it touches, the
  // thread-local `connections` lazily creates one fresh openLocal connection. (Shared
  // DBs are already present from setOverride and are REUSED, not recreated -- that is
  // C2, the in-memory-sharing property; see SPEC.md.)
  rule <k> handleRequest => .K ... </k>
       <own> OWN:List => OWN mkLocals(N) </own>
       <accesses> N:Int </accesses>
       requires N >=Int 0

  syntax List ::= mkLocals ( Int ) [function]
  rule mkLocals(0) => .List
  rule mkLocals(N:Int) => ListItem(openLocal) mkLocals(N -Int 1) requires N >Int 0

  // ---- closeAll : the loop that closes every owned connection -------------------
  // Models _close_connections() -> connections.close_all() (django/db/utils.py:207),
  // which iterates this thread's connections and calls close() on each. We drain
  // <own> head-first into <closed>, applying close() to each element.
  rule <k> closeAll => closeAll ... </k>
       <own> ListItem(S:ConnState) REST:List => REST </own>
       <closed> D:List => D ListItem(close(S)) </closed>                 [closeStep]
  rule <k> closeAll => .K ... </k>
       <own> .List </own>                                               [closeDone]

  // <closed>: accumulator for connections already processed by closeAll.
  // (Declared as an optional cell so configurations that never run closeAll omit it.)
  configuration <closed> .List </closed>  [exit]
endmodule
