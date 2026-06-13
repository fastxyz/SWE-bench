// mini-server-spec.k — reachability claims for the V1 fix.
// Constructed, NOT machine-checked (the MVP does not run kompile/kprove).
//
// Two claims, both [all-path] (the per-thread fragment is deterministic):
//   (CLOSEALL) the loop circularity for connections.close_all();
//   (PRT)      the process_request_thread contract that reuses (CLOSEALL).

requires "mini-server.k"

module MINI-SERVER-SPEC-SYNTAX
  imports MINI-SERVER-SYNTAX
endmodule

module VERIFICATION
  imports MINI-SERVER-SPEC-SYNTAX
  imports MINI-SERVER
  imports LIST
  imports K-EQUAL

  // --- [simplification] lemmas the arithmetic / list folds need -----------------

  // L1: closeList distributes over juxtaposition (list concatenation). Lets the
  //     circularity's inductive step recombine D ListItem(close(S)) closeList(REST)
  //     into D closeList(ListItem(S) REST).
  rule closeList(L1:List L2:List) => closeList(L1) closeList(L2)   [simplification]

  // L2: closing the result of closeList is idempotent (close is a retraction onto
  //     {openShared, closed}); not strictly needed for the claims below but documents
  //     that re-closing -- e.g. the request_finished signal AND _close_connections --
  //     is safe. close(close(S)) = close(S).
  rule closeList(closeList(L:List)) => closeList(L)               [simplification]

  // L3: a closed-form list of openLocal folds to a closed-form list of closed.
  rule closeList(mkLocals(N:Int)) => mkClosed(N)
       requires N >=Int 0                                         [simplification]
endmodule

module MINI-SERVER-SPEC
  imports VERIFICATION

  // mkClosed(N) / sharedOnly: spec vocabulary used in the postconditions.
  syntax List ::= mkClosed ( Int ) [function]
  rule mkClosed(0) => .List
  rule mkClosed(N:Int) => ListItem(closed) mkClosed(N -Int 1) requires N >Int 0

  // ============================================================================
  // (CLOSEALL) -- LOOP CIRCULARITY for connections.close_all().
  //
  // Generalized over the running accumulator D (already-processed conns) and the
  // remaining list L. Running closeAll drains L into <closed>, applying close() to
  // every element: the closed form is D closeList(L). No counter side condition is
  // needed -- the list strictly shrinks, so it is also a termination measure.
  // ============================================================================
  claim
    <k> closeAll => .K ... </k>
    <own>    L:List => .List          </own>
    <closed> D:List => D closeList(L) </closed>
    [all-path]

  // ============================================================================
  // (PRT) -- the process_request_thread CONTRACT (the function the fix changes).
  //
  // Precondition: the thread starts with an EMPTY thread-local connection view
  //   (<own> = .List -- a fresh worker thread); the override OV holds only OPEN,
  //   SHARED connections; the request touches N >= 0 distinct non-shared DBs.
  // Postcondition: after setOverride ; handleRequest ; closeAll, the worker thread's
  //   final connection multiset (<closed>) is closeList(OV mkLocals(N)) =
  //   closeList(OV) mkClosed(N): every shared conn is PRESERVED (openShared) and every
  //   non-shared conn the request opened is CLOSED. <own> is drained to .List.
  //
  // Corollary (the bug fix, see PROOF.md): closeList(OV) mkClosed(N) contains NO
  //   openLocal -- i.e. no thread-local DB connection leaks past the request (C1/C3) --
  //   and contains every openShared of OV unchanged -- i.e. the in-memory DB survives
  //   (C2-preserve).
  // ============================================================================
  claim
    <k> setOverride ; handleRequest ; closeAll => .K ... </k>
    <own>      .List => .List                          </own>
    <closed>   .List => closeList(OV) mkClosed(N)       </closed>
    <override> OV:List                                 </override>
    <accesses> N:Int                                   </accesses>
    requires N >=Int 0 andBool allShared(OV)
    [all-path]

  // allShared(L): every entry of L is openShared (the override invariant established
  // by LiveServerTestCase.setUpClass via inc_thread_sharing()).
  syntax Bool ::= allShared ( List ) [function, total]
  rule allShared(.List) => true
  rule allShared(ListItem(openShared) REST:List) => allShared(REST)
  rule allShared(ListItem(openLocal)  _:List)     => false
  rule allShared(ListItem(closed)     _:List)     => false
endmodule
