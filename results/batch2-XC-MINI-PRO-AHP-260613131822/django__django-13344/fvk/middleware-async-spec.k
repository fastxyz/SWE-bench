// middleware-async-spec.k
// =====================================================================
// Reachability claims over middleware-async.k.  All [all-path].
// "constructed, not machine-checked" (the MVP does not run kprove).
//
// Naming: uppercase logical Bools G, A, AMW (async-ness flags), H Callable.
// =====================================================================
requires "middleware-async.k"

module MIDDLEWARE-ASYNC-SPEC-SYNTAX
  imports MIDDLEWARE-ASYNC-SYNTAX
endmodule

module VERIFICATION
  imports MIDDLEWARE-ASYNC-SPEC-SYNTAX
  imports MIDDLEWARE-ASYNC
  imports K-EQUAL
endmodule

module MIDDLEWARE-ASYNC-SPEC
  imports VERIFICATION

  // (BASE) The initial handler cer(get_response) reports the flag of get_response.
  //        In ASGI get_response = _get_response_async (true), a0 = is_async (true),
  //        so the chain invariant holds on entry.
  claim <k> iscf(cer(raw(B:Bool))) ==Bool B => true ... </k>   [all-path]

  // (INIT) FUNCTION CONTRACT for the *corrected* constructor:
  //        the instance's iscoroutinefunction marker EQUALS its real async
  //        behaviour, for EVERY handler flag G.  This is the property the bug
  //        violated.  Pre/post: requires (none); reaches `true`.
  //        iscf(initCorrect(G)) = G = runsAsync(initCorrect(G)).
  claim <k> iscf(initCorrect(G:Bool)) ==Bool runsAsync(initCorrect(G)) => true ... </k>   [all-path]

  // (STEP) LOOP CIRCULARITY for the chain-building loop (load_middleware):
  //        if the incoming handler satisfies the invariant iscf(H) == A, then the
  //        outgoing handler satisfies it too: iscf(buildHandler(Amw,H,A)) == nextA(Amw).
  //        Generalized over Amw, H, A (the accumulator/counter analogue).
  claim <k> iscf(buildHandler(AMW:Bool, H:Callable, A:Bool)) ==Bool nextA(AMW) => true ... </k>
    requires iscf(H) ==Bool A
    [all-path]

  // (REFUTATION) The *pre-fix* constructor BREAKS (INIT).  This claim is
  //        EXPECTED TO FAIL: kprove must NOT return #Top.  The residual goal is
  //        the counterexample G = true (an async handler):
  //            iscf(initBuggy(true)) = false  !=  runsAsync(initBuggy(true)) = true.
  //        A failing proof here is the bug, surfaced (benefit #2).
  claim <k> iscf(initBuggy(G:Bool)) ==Bool runsAsync(initBuggy(G)) => true ... </k>   [all-path]
endmodule
