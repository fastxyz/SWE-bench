// middleware-async.k
// =====================================================================
// Mini flag-propagation semantics for Django's sync/async middleware
// adapter dispatch (django/utils/deprecation.py::MiddlewareMixin and
// django/core/handlers/{base,exception}.py).
//
// ABSTRACTION (the in-domain fragment where the bug lives)
// -------------------------------------------------------------------
// The async-ness of *every* callable is collapsed to a single Bool:
//
//     true  ==  asyncio.iscoroutinefunction(callable) is True
//     false ==  it is not
//
// We model ONLY the bookkeeping that decides that Bool, because the bug
// is entirely a Bool-bookkeeping mistake (a marker that is never set).
// Real coroutine objects, `await`, and asgiref's sync_to_async /
// async_to_sync *internals* are an ESCALATION BOUNDARY (matching logic
// binders + concurrency, out of the mini-X fast path). We model their
// *flag contract* only, trusted by inspection -- see SPEC.md S1..S5.
// =====================================================================

module MIDDLEWARE-ASYNC-SYNTAX
  imports BOOL-SYNTAX

  // A "callable" is represented by the data that determines iscf(.).
  syntax Callable ::= "raw" "(" Bool ")"                          // a plain callable carrying its flag
                    | "cer" "(" Callable ")"                      // convert_exception_to_response(g)
                    | "adapt" "(" Bool "," Callable "," Bool ")"  // adapt_method_mode(is_async, h, h_is_async)
                    | "inst" "(" Bool "," Bool ")"                // MiddlewareMixin instance: inst(marker, getRespFlag)
                    // constructors:
                    | "initCorrect" "(" Bool ")"                  // __init__ that DOES call _async_check()  (post-fix)
                    | "initBuggy"   "(" Bool ")"                  // __init__ that OMITS _async_check()      (pre-fix)
                    | "buildHandler" "(" Bool "," Callable "," Bool ")" // one chain-loop iteration (post-fix)

  // Observers (functions, total Bool):
  syntax Bool ::= "iscf"      "(" Callable ")"   [function]   // asyncio.iscoroutinefunction(.)
                | "runsAsync" "(" Callable ")"   [function]   // does __call__ dispatch to __acall__ (return a coroutine)?
                | "nextA"     "(" Bool ")"       [function]   // handler_is_async tracked after a step
endmodule

module MIDDLEWARE-ASYNC
  imports MIDDLEWARE-ASYNC-SYNTAX
  imports BOOL

  // ---- constructors -------------------------------------------------
  // _async_check() sets self._is_coroutine := iscoroutinefunction(get_response).
  // initCorrect(G): self.get_response flag = G; marker set to iscf(get_response) = G.
  rule initCorrect(G) => inst(G, G)
  // initBuggy(G): _async_check() never runs, so the marker stays unset (false).
  rule initBuggy(G)   => inst(false, G)

  // ---- observers ----------------------------------------------------
  // [S1] iscf of a raw callable is its flag (async def / sync def / SyncToAsync / async_to_sync).
  rule iscf(raw(B)) => B
  // [S2] convert_exception_to_response builds an async `inner` iff its arg is a
  //      coroutine function, so it PRESERVES the flag.            (exception.py:34)
  rule iscf(cer(C)) => iscf(C)
  // [S3] iscoroutinefunction on a MiddlewareMixin instance reads _is_coroutine.
  //      (a non-function object is a coroutine-function iff it carries the marker)
  rule iscf(inst(MARK, _G)) => MARK
  // [S4] adapt_method_mode TRUSTS its passed handler-flag M (3rd arg, handler_is_async):
  //        M == is_async -> returns handler unchanged       -> flag = iscf(C)
  //        M != is_async -> wraps with (a)sync_to_(a)sync   -> flag = is_async    (base.py:97-122)
  rule iscf(adapt(A, C, M)) => iscf(C)   requires M ==Bool A
  rule iscf(adapt(A, _C, M)) => A        requires M =/=Bool A
  // [S5] a MiddlewareMixin instance returns a coroutine from __call__ iff its
  //      get_response is a coroutine function.                 (deprecation.py:110-113)
  rule runsAsync(inst(_MARK, G)) => G

  // ---- one chain-building iteration (load_middleware loop body) ------
  // Incoming handler H with tracked flag A. The middleware runs in mode Amw.
  //   handler' = adapt(Amw, H, A)
  //   mw       = initCorrect( iscf(handler') )      // get_response = handler'
  //   H'       = cer(mw)                            // wrapped for the next layer
  //   a'       = Amw
  rule buildHandler(Amw, H, A) => cer(initCorrect(iscf(adapt(Amw, H, A))))
  rule nextA(Amw) => Amw
endmodule
